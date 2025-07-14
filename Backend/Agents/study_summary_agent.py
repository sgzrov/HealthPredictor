import openai
import logging
from typing import Optional, Any, Generator

logger = logging.getLogger(__name__)

class StudySummaryAgent:
    def __init__(self, api_key: str, prompt_path: str, model: str = "gpt-4o-mini") -> None:
        self.api_key = api_key
        self.model = model
        self.client = openai.OpenAI(api_key = api_key)

        try:
            with open(prompt_path, "r", encoding="utf-8") as f:
                self.prompt = f.read()
        except Exception as e:
            logger.error(f"Error reading prompt file: {e}")
            raise

    def summarize_stream(self, text: str, prompt: Optional[str] = None) -> Generator[Any, None, None]:
        instructions = prompt if prompt is not None else self.prompt

        try:
            response = self.client.responses.create(
                model = self.model,
                input = f"{instructions}\n\nText to summarize:\n{text}",
                stream = True
            )
            for chunk in response:
                yield chunk
        except openai.APIError as e:
            logger.error(f"OpenAI API error: {e}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error in summarize_stream: {e}")
            raise