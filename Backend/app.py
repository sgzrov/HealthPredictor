import os
import logging
import json
import io
from fastapi import FastAPI, UploadFile, File, HTTPException, Form, Depends
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
    user_input: Optional[str] = None
    conversation_id: Optional[str] = None

class GenerateOutcomeRequest(BaseModel):
    s3_url: str
    user_input: str

def extract_text_from_chunk(chunk: Any, full_response: str = "") -> str:
    logger.debug(f"🔍 BACKEND: extract_text_from_chunk called with chunk type: {getattr(chunk, 'type', 'unknown')}")

    if hasattr(chunk, 'type'):
        if chunk.type == 'text_delta':
            if hasattr(chunk, 'delta') and chunk.delta and hasattr(chunk.delta, 'text'):
                text = chunk.delta.text or ""
                logger.debug(f"🔍 BACKEND: text_delta chunk, extracted: '{text}'")
                return text

        elif chunk.type == 'response.output_text.delta':
            if hasattr(chunk, 'delta') and chunk.delta:
                text = chunk.delta or ""
                logger.debug(f"🔍 BACKEND: response.output_text.delta chunk, extracted: '{text}'")
                return text

        elif chunk.type == 'response.output_text.done':
            if hasattr(chunk, 'text') and chunk.text:
                remaining_text = chunk.text[len(full_response):]
                text = remaining_text or ""
                logger.debug(f"🔍 BACKEND: response.output_text.done chunk, extracted: '{text}'")
                return text

        # Handle code interpreter specific chunk types
        elif chunk.type == 'response.output_text':
            if hasattr(chunk, 'text') and chunk.text:
                text = chunk.text or ""
                logger.debug(f"🔍 BACKEND: response.output_text chunk, extracted: '{text}'")
                return text

        # Handle tool calls and other code interpreter events
        elif chunk.type in ['tool_call', 'tool_result', 'response.output_tool_calls']:
            # Skip tool-related chunks as they don't contain user-facing text
            logger.debug(f"🔍 BACKEND: Skipping tool-related chunk: {chunk.type}")
            return ""

        # Handle any other chunk types that might contain text
        elif hasattr(chunk, 'text') and chunk.text:
            text = chunk.text or ""
            logger.debug(f"🔍 BACKEND: Generic text chunk, extracted: '{text}'")
            return text

    # Fallback: try to extract text from any attribute that might contain it
    for attr in ['text', 'content', 'delta']:
        if hasattr(chunk, attr):
            value = getattr(chunk, attr)
            if value and isinstance(value, str):
                logger.debug(f"🔍 BACKEND: Fallback extraction from {attr}: '{value}'")
                return value

    logger.debug(f"🔍 BACKEND: No text extracted from chunk")
    return ""

def process_streaming_response(response: Any, conversation_callback: Optional[Callable[[str], None]] = None) -> Any:
    full_response = ""
    chunk_count = 0

    for chunk in response:
        chunk_count += 1
        logger.debug(f"🔍 BACKEND: Processing chunk {chunk_count}: type={getattr(chunk, 'type', 'unknown')}")

        text = extract_text_from_chunk(chunk, full_response)
        if text:
            full_response += text
            logger.debug(f"🔍 BACKEND: Extracted text: '{text}'")
            yield f"data: {json.dumps({'content': text, 'done': False})}\n\n"
        else:
            logger.debug(f"🔍 BACKEND: No text extracted from chunk {chunk_count}")

    logger.debug(f"🔍 BACKEND: Stream complete, total chunks: {chunk_count}, full response length: {len(full_response)}")

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
    request: AnalyzeHealthDataRequest,
    user = Depends(verify_clerk_jwt)
):
    logger.debug(f"🔍 BACKEND: /analyze-health-data/ called")
    logger.debug(f"🔍 BACKEND: s3_url: {request.s3_url}")
    logger.debug(f"🔍 BACKEND: user_input: {request.user_input}")
    logger.debug(f"🔍 BACKEND: conversation_id: {request.conversation_id}")
    logger.debug(f"🔍 BACKEND: user: {user.get('sub', 'unknown')}")

    if s3_storage_service is None:
        logger.error("🔍 BACKEND: S3 storage service is None")
        raise HTTPException(status_code = 503, detail = "Tigris storage not configured")

    try:
        # Download file from S3
        logger.debug(f"🔍 BACKEND: Attempting to download file from S3 URL: {request.s3_url}")
        file_obj = s3_storage_service.download_file_from_url(request.s3_url)
        logger.debug(f"🔍 BACKEND: Successfully downloaded file from S3")

        # Handle optional user_input
        user_input_str = request.user_input or ""
        logger.debug(f"🔍 BACKEND: User input string: '{user_input_str}'")
        save_conversation, _ = setup_conversation_history(request.conversation_id, user_input_str)
        logger.debug(f"🔍 BACKEND: Conversation history setup complete")

        async def generate_stream():
            try:
                logger.debug("🔍 BACKEND: Starting health data analysis stream")
                logger.debug(f"🔍 BACKEND: Calling chat_agent.analyze_health_data")
                response = chat_agent.analyze_health_data(file_obj, user_input_str, conversation_id=request.conversation_id)
                logger.debug(f"🔍 BACKEND: Got response from chat_agent, processing stream")
                for event in process_streaming_response(response, save_conversation):
                    logger.debug(f"🔍 BACKEND: Yielding event: {event}")
                    yield event
                logger.debug("🔍 BACKEND: Stream processing complete")
            except Exception as e:
                logger.error(f"🔍 BACKEND: Health analysis error: {e}")
                logger.error(f"🔍 BACKEND: Error type: {type(e)}")
                import traceback
                logger.error(f"🔍 BACKEND: Traceback: {traceback.format_exc()}")
                yield f"data: {json.dumps({'error': str(e), 'done': True})}\n\n"

        logger.debug("🔍 BACKEND: Creating streaming response")
        return create_streaming_response(generate_stream)

    except Exception as e:
        logger.error(f"🔍 BACKEND: Error in analyze_health_data: {e}")
        logger.error(f"🔍 BACKEND: Error type: {type(e)}")
        import traceback
        logger.error(f"🔍 BACKEND: Traceback: {traceback.format_exc()}")
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
    request: GenerateOutcomeRequest,
    user = Depends(verify_clerk_jwt)
):
    logger.debug(f"/generate-outcome/ called with s3_url: {request.s3_url}, user_input: {request.user_input} by user: {user.get('sub', 'unknown')}")

    if s3_storage_service is None:
        raise HTTPException(status_code = 503, detail = "Tigris storage not configured")

    try:
        # Download file from S3
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

@app.post("/upload-health-data/")
async def upload_health_data(
    file: UploadFile = File(...),
    user = Depends(verify_clerk_jwt)
):
    logger.debug(f"/upload-health-data/ called by user: {user.get('sub', 'unknown')}")

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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host = "0.0.0.0", port = 8000)
# Force deployment
