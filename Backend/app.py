import os
import logging
import json
import io
from fastapi import FastAPI, UploadFile, File, HTTPException, Form, Depends
from fastapi.responses import StreamingResponse
from dotenv import load_dotenv
from pydantic import BaseModel
from typing import Optional, Callable, Any

from Agents.chat_agent import ChatAgent
from Agents.study_outcome_agent import StudyOutcomeAgent
from Agents.study_summary_agent import StudySummaryAgent
from Agents.Helpers.code_interpreter_selector import CodeInterpreterSelector
from auth import verify_clerk_jwt

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)
logging.getLogger('chat_agent').setLevel(logging.DEBUG)

load_dotenv()

app = FastAPI()

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

def process_streaming_response(response: Any, conversation_callback: Optional[Callable[[str], None]] = None) -> Any:
    full_response = ""

    for chunk in response:
        text = extract_text_from_chunk(chunk, full_response)
        if text:
            full_response += text
            yield f"data: {json.dumps({'content': text, 'done': False})}\n\n"

    if conversation_callback and full_response.strip():
        conversation_callback(full_response.strip())
    yield f"data: {json.dumps({'content': '', 'done': True})}\n\n"

def setup_conversation_history(conversation_id: Optional[str], user_input: str) -> tuple[Optional[Callable[[str], None]], None]:
    if not conversation_id:
        return None, None

    chat_agent._append_user_message(conversation_id, user_input)
    def save_conversation(full_response: str) -> None:
        chat_agent._append_assistant_response(conversation_id, full_response)

    return save_conversation, None

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
async def analyze_health_data(
    file: UploadFile = File(...),
    user_input: str = Form(...),
    conversation_id: str = Form(None),
    user = Depends(verify_clerk_jwt)
):
    logger.debug(f"/analyze-health-data/ called with user_input: {user_input} by user: {user.get('sub', 'unknown')}")

    try:
        file_bytes = await file.read()
        save_conversation, _ = setup_conversation_history(conversation_id, user_input)

        async def generate_stream():
            try:
                file_obj = io.BytesIO(file_bytes)
                response = chat_agent.analyze_health_data(file_obj, user_input, conversation_id=conversation_id)
                for event in process_streaming_response(response, save_conversation):
                    yield event
            except Exception as e:
                logger.error(f"Health analysis error: {e}")
                yield f"data: {json.dumps({'error': str(e), 'done': True})}\n\n"

        return create_streaming_response(generate_stream)

    except Exception as e:
        logger.error(f"Error in analyze_health_data: {e}")
        raise HTTPException(status_code = 500, detail = str(e))

@app.post("/simple-chat/")
async def simple_chat(
    request: SimpleChatRequest,
    user = Depends(verify_clerk_jwt)
):
    logger.debug(f"/simple-chat/ called with user_input: {request.user_input} by user: {user.get('sub', 'unknown')}")

    try:
        save_conversation, _ = setup_conversation_history(request.conversation_id, request.user_input)

        async def generate_stream():
            try:
                with open(PROMPT_PATHS["simple_chat"], "r", encoding="utf-8") as f:
                    simple_chat_prompt = f.read()
                response = chat_agent.simple_chat(request.user_input, prompt=simple_chat_prompt, conversation_id=request.conversation_id)
                for event in process_streaming_response(response, save_conversation):
                    yield event
            except Exception as e:
                logger.error(f"Simple chat error: {e}")
                yield f"data: {json.dumps({'error': str(e), 'done': True})}\n\n"

        return create_streaming_response(generate_stream)

    except Exception as e:
        logger.error(f"Error in simple_chat: {e}")
        raise HTTPException(status_code = 500, detail = str(e))

@app.post("/should-use-code-interpreter/")
async def should_use_code_interpreter(
    request: SelectorRequest,
    user = Depends(verify_clerk_jwt)
):
    logger.debug(f"/should-use-code-interpreter/ called by user: {user.get('sub', 'unknown')}")

    try:
        result = selector_agent.should_use_code_interpreter(request.user_input)
        use_code_interpreter = result == "yes"
        return {"use_code_interpreter": use_code_interpreter}
    except Exception as e:
        logger.error(f"Selector error: {e}")
        raise HTTPException(status_code = 500, detail = str(e))

@app.post("/generate-outcome/")
async def generate_outcome(
    file: UploadFile = File(...),
    user_input: str = Form(...),
    user = Depends(verify_clerk_jwt)
):
    logger.debug(f"/generate-outcome/ called with user_input: {user_input} by user: {user.get('sub', 'unknown')}")

    try:
        file_bytes = await file.read()

        async def generate_stream():
            try:
                file_obj = io.BytesIO(file_bytes)
                response = outcome_agent.generate_outcome_stream(file_obj, user_input)
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
async def summarize_study(
    request: SummarizeRequest,
    user = Depends(verify_clerk_jwt)
):
    logger.debug(f"/summarize-study/ called with text length: {len(request.text)} by user: {user.get('sub', 'unknown')}")

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
