import os
import logging
import json
import io
from fastapi import FastAPI, UploadFile, File, HTTPException, Depends, Request
from fastapi.responses import StreamingResponse
from dotenv import load_dotenv
from pydantic import BaseModel
from typing import Optional, Callable, Any

from Backend.Agents.chat_agent import ChatAgent
from Backend.Agents.study_outcome_agent import StudyOutcomeAgent
from Backend.Agents.study_summary_agent import StudySummaryAgent
from Backend.Agents.Helpers.code_interpreter_selector import CodeInterpreterSelector
from Backend.auth import verify_clerk_jwt
from Backend.s3_storage_service import S3StorageService
from Backend.Database.chat_history import get_chat_history, get_all_conversation_ids, get_conversation_last_message_times

from Backend.text_extraction_router import router as text_extraction_router

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)
logging.getLogger('chat_agent').setLevel(logging.DEBUG)

load_dotenv()

app = FastAPI()
app.include_router(text_extraction_router)

try:
    s3_storage_service = S3StorageService()
except ValueError as e:
    logger.warning(f"S3StorageService initialization failed: {e}")
    s3_storage_service = None

api_key = os.getenv("OPENAI_API_KEY")
if not api_key:
    raise ValueError("OPENAI_API_KEY environment variable not set.")

PROMPT_DIR = os.path.join(os.path.dirname(__file__), "Prompts")
PROMPT_PATHS = {
    "chat": os.path.join(PROMPT_DIR, "ChatPrompt.txt"),
    "simple_chat": os.path.join(PROMPT_DIR, "SimpleChatPrompt.txt"),
    "code_interpreter_selector": os.path.join(PROMPT_DIR, "CodeInterpreterSelectorPrompt.txt"),
    "outcome": os.path.join(PROMPT_DIR, "OutcomePrompt.txt"),
    "summary": os.path.join(PROMPT_DIR, "SummaryPrompt.txt")
}

chat_agent = ChatAgent(api_key, prompt_path=PROMPT_PATHS["chat"])
selector_agent = CodeInterpreterSelector(api_key, prompt_path=PROMPT_PATHS["code_interpreter_selector"])
outcome_agent = StudyOutcomeAgent(api_key, prompt_path=PROMPT_PATHS["outcome"])
summary_agent = StudySummaryAgent(api_key, prompt_path=PROMPT_PATHS["summary"])

class SummarizeRequest(BaseModel):
    text: str

class SelectorRequest(BaseModel):
    user_input: str

class SimpleChatRequest(BaseModel):
    user_input: str
    conversation_id: Optional[str] = None

class AnalyzeHealthDataRequest(BaseModel):
    s3_url: str
    user_input: str
    conversation_id: Optional[str] = None

class GenerateOutcomeRequest(BaseModel):
    s3_url: str
    user_input: str

def extract_text_from_chunk(chunk: Any, full_response: str = "") -> str:
    if hasattr(chunk, 'type'):
        if chunk.type == 'text_delta':
            if hasattr(chunk, 'delta') and chunk.delta and hasattr(chunk.delta, 'text'):
                return chunk.delta.text or ""

        elif chunk.type == 'response.output_text.delta':
            if hasattr(chunk, 'delta') and chunk.delta:
                return chunk.delta or ""

        elif chunk.type == 'response.output_text.done':
            if hasattr(chunk, 'text') and chunk.text:
                remaining_text = chunk.text[len(full_response):]
                return remaining_text or ""
    return ""

def process_streaming_response(response: Any, conversation_callback: Optional[Callable[[str], None]] = None, partial_callback: Optional[Callable[[str], None]] = None) -> Any:
    full_response = ""

    for chunk in response:
        text = extract_text_from_chunk(chunk, full_response)
        if text:
            full_response += text
            yield f"data: {json.dumps({'content': text, 'done': False})}\n\n"

    if conversation_callback and full_response.strip():
        conversation_callback(full_response.strip())
    yield f"data: {json.dumps({'content': '', 'done': True})}\n\n"

def setup_conversation_history(conversation_id: Optional[str], user_input: str, user_id: str):
    print(f"[DEBUG] setup_conversation_history called with conversation_id={conversation_id}, user_input={user_input}, user_id={user_id}")
    logger.info(f"[setup_conversation_history] conversation_id={conversation_id}, user_input={user_input}, user_id={user_id}")
    if not conversation_id:
        return None, None, None
    chat_agent._append_user_message(conversation_id, user_id, user_input)

    def save_conversation(full_response: str) -> None:
        chat_agent._append_assistant_response(conversation_id, user_id, full_response)

    def save_partial_conversation(partial_response: str) -> None:
        chat_agent._append_partial_assistant_response(conversation_id, user_id, partial_response)

    return save_conversation, save_partial_conversation, None

def create_streaming_response(generator_func: Callable, **kwargs) -> StreamingResponse:
    return StreamingResponse(
        generator_func(**kwargs),
        media_type = "text/plain",
        headers = {
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "Content-Type": "text/event-stream",
        }
    )

@app.post("/analyze-health-data/")
async def analyze_health_data(request: AnalyzeHealthDataRequest, req: Request):
    user = verify_clerk_jwt(req)
    user_id = user['sub']
    print(f"[DEBUG] /analyze-health-data/ called with conversation_id={request.conversation_id}, user_id={user_id}")
    if s3_storage_service is None:
        logger.error("S3 storage service is None")
        raise HTTPException(status_code = 503, detail = "Tigris storage not configured")

    try:
        file_obj = s3_storage_service.download_file_from_url(request.s3_url)
        logger.info(f"[analyze-health-data] File downloaded from S3: {request.s3_url}")

        user_input_str = request.user_input
        save_conversation, save_partial_conversation, _ = setup_conversation_history(request.conversation_id, user_input_str, user_id)

        async def generate_stream():
            try:
                response = chat_agent.analyze_health_data(file_obj, user_input_str, user_id, conversation_id = request.conversation_id)
                for event in process_streaming_response(response, save_conversation, save_partial_conversation):
                    yield event
            except Exception as e:
                logger.error(f"Health analysis error: {e}")
                yield f"data: {json.dumps({'error': str(e), 'done': True})}\n\n"

        return create_streaming_response(generate_stream)

    except Exception as e:
        logger.error(f"Error in analyze_health_data: {e}")
        raise HTTPException(status_code = 500, detail = str(e))

@app.post("/simple-chat/")
async def simple_chat(request: SimpleChatRequest, req: Request):
    user = verify_clerk_jwt(req)
    user_id = user['sub']
    try:
        save_conversation, save_partial_conversation, _ = setup_conversation_history(request.conversation_id, request.user_input, user_id)

        async def generate_stream():
            try:
                with open(PROMPT_PATHS["simple_chat"], "r", encoding = "utf-8") as f:
                    simple_chat_prompt = f.read()
                response = chat_agent.simple_chat(request.user_input, user_id, prompt = simple_chat_prompt, conversation_id = request.conversation_id)
                for event in process_streaming_response(response, save_conversation, save_partial_conversation):
                    yield event
            except Exception as e:
                logger.error(f"Simple chat error: {e}")
                yield f"data: {json.dumps({'error': str(e), 'done': True})}\n\n"

        return create_streaming_response(generate_stream)

    except Exception as e:
        logger.error(f"Error in simple_chat: {e}")
        raise HTTPException(status_code = 500, detail = str(e))

@app.post("/should-use-code-interpreter/")
async def should_use_code_interpreter(request: SelectorRequest, _ = Depends(verify_clerk_jwt)):
    try:
        result = selector_agent.should_use_code_interpreter(request.user_input)
        use_code_interpreter = result == "yes"
        return {"use_code_interpreter": use_code_interpreter}
    except Exception as e:
        logger.error(f"Selector error: {e}")
        raise HTTPException(status_code = 500, detail = str(e))

@app.post("/generate-outcome/")
async def generate_outcome(request: GenerateOutcomeRequest, _ = Depends(verify_clerk_jwt)):
    if s3_storage_service is None:
        logger.error("S3 storage service is None")
        raise HTTPException(status_code = 503, detail = "Tigris storage not configured")

    try:
        file_obj = s3_storage_service.download_file_from_url(request.s3_url)

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

@app.post("/upload-health-data/")
async def upload_health_data(file: UploadFile = File(...), user = Depends(verify_clerk_jwt)):

    if s3_storage_service is None:
        raise HTTPException(status_code = 503, detail = "Tigris storage not configured")

    try:
        user_id = user.get('sub', 'unknown')
        file_bytes = await file.read()
        file_obj = io.BytesIO(file_bytes)

        filename = file.filename or "user_health_data.csv"
        s3_url = s3_storage_service.upload_health_data_file(file_obj, user_id, filename)

        logger.info(f"Successfully uploaded health data for user {user_id}: {s3_url}")
        return {"s3_url": s3_url, "message": "Health data uploaded successfully"}

    except Exception as e:
        logger.error(f"Error uploading health data: {e}")
        raise HTTPException(status_code = 500, detail = str(e))

@app.get("/chat-history/{conversation_id}")
def fetch_chat_history(conversation_id: str, request: Request):
    user = verify_clerk_jwt(request)
    user_id = user['sub']
    print(f"[DEBUG][API] FETCH CHAT HISTORY: conv_id={conversation_id}, user_id={user_id}")
    messages = get_chat_history(conversation_id, user_id)
    print(f"[PRINT][API] FETCH: conv_id={conversation_id}, user_id={user_id}, num_messages={len(messages)}")
    import logging
    logger = logging.getLogger("chat_history")
    logger.info(f"[API] FETCH: conv_id={conversation_id}, user_id={user_id}, num_messages={len(messages)}")
    return [
        {
            "role": m.role,
            "content": m.content,
            "timestamp": m.timestamp.isoformat() if m.timestamp else None
        }
        for m in messages
    ]

@app.get("/chat-sessions/")
def list_chat_sessions(request: Request):
    user = verify_clerk_jwt(request)
    user_id = user['sub']
    print(f"[DEBUG][API] LIST CHAT SESSIONS: user_id={user_id}")
    # Return conversation_id and last_message_at for each session
    return {"sessions": get_conversation_last_message_times(user_id)}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host = "0.0.0.0", port = 8000)
