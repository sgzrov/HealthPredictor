import openai
import logging
from typing import Optional

logger = logging.getLogger(__name__)

class CodeInterpreterSelector:
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

    def should_use_code_interpreter(self, user_input: str, prompt: Optional[str] = None) -> str:
        instructions = prompt if prompt is not None else self.prompt

        try:
            response = self.client.responses.create(
                model = self.model,
                input = f"{instructions}\nUser input: {user_input}"
            )

            for out_item in response.output:
                if getattr(out_item, "type", None) == "message":
                    content_elements = getattr(out_item, "content", [])
                    for element in content_elements:
                        text = getattr(element, "text", None)
                        if text is not None:
                            answer = text.strip().lower()
                            logger.info(f"Code interpreter selection response: {answer}")
                            if "yes" in answer:
                                return "yes"
            return "no"

        except openai.APIError as e:
            logger.error(f"OpenAI API error: {e}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error in should_use_code_interpreter: {e}")
            raise