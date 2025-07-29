import os
import logging
import json
from fastapi import FastAPI, HTTPException, Depends, Request
from dotenv import load_dotenv

from Backend.Agents.chat_agent import ChatAgent
from Backend.Agents.study_outcome_agent import StudyOutcomeAgent
from Backend.Agents.study_summary_agent import StudySummaryAgent
from Backend.Agents.Helpers.code_interpreter_selector import CodeInterpreterSelector

from Backend.auth import verify_clerk_jwt

from Backend.Database.db import SessionLocal
from Backend.Database.s3_storage import S3Storage

from Backend.Utils.streaming_utils import process_streaming_response, create_streaming_response
from Backend.Utils.conversation_utils import setup_conversation_history

from Backend.Models.requests import SummarizeRequest, SelectorRequest, SimpleChatRequest, ChatWithCIRequest, GenerateOutcomeRequest

from Backend.Database import *

from Backend.Routers.text_extraction_router import router as text_extraction_router
from Backend.Routers.file_router import router as file_router
from Backend.Routers.chat_router import router as chat_router
from Backend.Routers.study_router import router as study_router

logging.basicConfig(level = logging.DEBUG)
logger = logging.getLogger(__name__)
logging.getLogger('chat_agent').setLevel(logging.DEBUG)

load_dotenv()

app = FastAPI()

app.include_router(text_extraction_router)
app.include_router(file_router)
app.include_router(chat_router)
app.include_router(study_router)

try:
    s3_storage = S3Storage()
except ValueError as e:
    logger.warning(f"S3Storage initialization failed: {e}")
    s3_storage = None

api_key = os.getenv("OPENAI_API_KEY")
if not api_key:
    raise ValueError("OPENAI_API_KEY environment variable not set.")

PROMPT_DIR = os.path.join(os.path.dirname(__file__), "Prompts")
PROMPT_PATHS = {
    "chat": os.path.join(PROMPT_DIR, "ChatCIPrompt.txt"),
    "simple_chat": os.path.join(PROMPT_DIR, "SimpleChatPrompt.txt"),
    "code_interpreter_selector": os.path.join(PROMPT_DIR, "CodeInterpreterSelectorPrompt.txt"),
    "outcome": os.path.join(PROMPT_DIR, "OutcomePrompt.txt"),
    "summary": os.path.join(PROMPT_DIR, "SummaryPrompt.txt")
}

chat_agent = ChatAgent(api_key, prompt_path = PROMPT_PATHS["chat"])
selector_agent = CodeInterpreterSelector(api_key, prompt_path = PROMPT_PATHS["code_interpreter_selector"])
outcome_agent = StudyOutcomeAgent(api_key, prompt_path = PROMPT_PATHS["outcome"])
summary_agent = StudySummaryAgent(api_key, prompt_path = PROMPT_PATHS["summary"])

@app.post("/chat-with-ci/")
async def chat_with_ci(request: ChatWithCIRequest, req: Request):
    user = verify_clerk_jwt(req)
    user_id = user['sub']
    print(f"[DEBUG] /chat-with-ci/ called with conversation_id={request.conversation_id}, user_id={user_id}")
    if s3_storage is None:
        logger.error("S3 storage is None")
        raise HTTPException(status_code = 503, detail = "Tigris storage not configured")

    async def generate_stream():
        session = SessionLocal()
        try:
            file_obj = s3_storage.download_file_from_url(request.s3_url)
            logger.info(f"[chat-with-ci] File downloaded from S3: {request.s3_url}")

            user_input_str = request.user_input
            save_conversation, save_partial_conversation, new_conversation_id = setup_conversation_history(request.conversation_id, user_input_str, user_id, session, chat_agent)

            try:
                # Use the new conversation_id if one was created
                conversation_id = new_conversation_id or request.conversation_id
                response = chat_agent.analyze_health_data(file_obj, user_input_str, user_id, conversation_id = conversation_id, session = session)
                for event in process_streaming_response(response, save_conversation, save_partial_conversation):
                    yield event
            except Exception as e:
                logger.error(f"Health analysis error: {e}")
                yield f"data: {json.dumps({'error': str(e), 'done': True})}\n\n"
        finally:
            session.close()

    return create_streaming_response(generate_stream)

@app.post("/simple-chat/")
async def simple_chat(request: SimpleChatRequest, req: Request):
    user = verify_clerk_jwt(req)
    user_id = user['sub']

    async def generate_stream():
        session = SessionLocal()
        try:
            save_conversation, save_partial_conversation, new_conversation_id = setup_conversation_history(request.conversation_id, request.user_input, user_id, session, chat_agent)

            try:
                with open(PROMPT_PATHS["simple_chat"], "r", encoding = "utf-8") as f:
                    simple_chat_prompt = f.read()
                # Use the new conversation_id if one was created
                conversation_id = new_conversation_id or request.conversation_id
                response = chat_agent.simple_chat(request.user_input, user_id, prompt = simple_chat_prompt, conversation_id = conversation_id, session = session)
                for event in process_streaming_response(response, save_conversation, save_partial_conversation):
                    yield event
            except Exception as e:
                logger.error(f"Simple chat error: {e}")
                yield f"data: {json.dumps({'error': str(e), 'done': True})}\n\n"
        finally:
            session.close()

    return create_streaming_response(generate_stream)

@app.post("/should-use-code-interpreter/")
async def should_use_code_interpreter(request: SelectorRequest, _ = Depends(verify_clerk_jwt)):
    try:
        result = selector_agent.should_use_code_interpreter(request.user_input)
        use_code_interpreter = result.lower() == "yes"
        return {"use_code_interpreter": use_code_interpreter}
    except Exception as e:
        logger.error(f"Selector error: {e}")
        raise HTTPException(status_code = 500, detail = str(e))

@app.post("/generate-outcome/")
async def generate_outcome(request: GenerateOutcomeRequest, _ = Depends(verify_clerk_jwt)):
    if s3_storage is None:
        logger.error("S3 storage is None")
        raise HTTPException(status_code = 503, detail = "Tigris storage not configured")

    try:
        file_obj = s3_storage.download_file_from_url(request.s3_url)

        async def generate_stream():
            try:
                response = outcome_agent.generate_outcome_stream(file_obj, request.user_input)
                for event in process_streaming_response(response):
                    yield event
            except Exception as e:
                logger.error(f"Outcome generation error: {e}")
                yield f"data: {json.dumps({'error': str(e), 'done': True})}\n\n"

        return create_streaming_response(generate_stream)

    except Exception as e:
        logger.error(f"Error in generate_outcome: {e}")
        raise HTTPException(status_code = 500, detail = str(e))

@app.post("/summarize-study/")
async def summarize_study(request: SummarizeRequest, _ = Depends(verify_clerk_jwt)):
    try:
        async def generate_stream():
            try:
                response = summary_agent.summarize_stream(request.text)
                for event in process_streaming_response(response):
                    yield event
            except Exception as e:
                logger.error(f"Summary generation error: {e}")
                yield f"data: {json.dumps({'error': str(e), 'done': True})}\n\n"
        return create_streaming_response(generate_stream)

    except Exception as e:
        logger.error(f"Error in summarize_study: {e}")
        raise HTTPException(status_code = 500, detail = str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host = "0.0.0.0", port = 8000)
