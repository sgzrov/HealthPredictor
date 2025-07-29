import json
from typing import Any, Optional, Callable
from fastapi.responses import StreamingResponse

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