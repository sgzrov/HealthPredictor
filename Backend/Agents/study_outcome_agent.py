import openai
import logging
from typing import BinaryIO, Optional, Any, Generator

logger = logging.getLogger(__name__)

class StudyOutcomeAgent:
    def __init__(self, api_key: str, prompt_path: str, model: str = "gpt-4o-mini") -> None:
        self.api_key = api_key
        self.model = model
        self.client = openai.OpenAI(api_key=api_key)

        try:
            with open(prompt_path, "r", encoding="utf-8") as f:
                self.prompt = f.read()
        except Exception as e:
            logger.error(f"Error reading prompt file: {e}")
            raise

    def generate_outcome_stream(self, file_obj: BinaryIO, user_input: str, prompt: Optional[str] = None, filename: str = "user_health_data.csv") -> Generator[Any, None, None]:
        instructions = prompt if prompt is not None else self.prompt

        try:
            file_obj.seek(0)
            file = self.client.files.create(
                file = (filename, file_obj, "text/csv"),
                purpose = "assistants"
            )

            response = self.client.responses.create(
                model = self.model,
                tools = [
                    {
                        "type": "code_interpreter",
                        "container": {
                            "type": "auto",
                            "file_ids": [file.id]
                        }
                    }
                ],
                instructions = instructions,
                input = user_input,
                stream = True
            )

            for chunk in response:
                yield chunk
        except openai.APIError as e:
            logger.error(f"OpenAI API error: {e}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error in generate_outcome_stream: {e}")
            raise