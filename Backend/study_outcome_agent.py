import openai
import logging
from typing import BinaryIO
import os

logger = logging.getLogger(__name__)

class StudyOutcomeAgent:
    def __init__(self, api_key, prompt_path):
        self.api_key = api_key
        self.model = "gpt-4o-mini"
        self.client = openai.OpenAI(api_key=api_key)

        with open(prompt_path, "r", encoding = "utf-8") as f:
            self.prompt = f.read()

    def generate_outcome(self, file_obj: BinaryIO, user_input: str, prompt = None) -> str:
        instructions = prompt if prompt is not None else self.prompt

        try:
            # Log user_input
            logger.info(f"user_input length: {len(user_input)}")
            logger.info(f"user_input sample: {user_input[:200]}")

            # Log file size and sample
            try:
                file_obj.seek(0, os.SEEK_END)
                file_size = file_obj.tell()
                file_obj.seek(0)
                file_sample = file_obj.read(500)
                file_obj.seek(0)
                logger.info(f"CSV file size: {file_size} bytes")
                logger.info(f"CSV file sample: {file_sample[:200]}")
            except Exception as e:
                logger.warning(f"Could not log file sample/size: {e}")

            file_obj.seek(0)
            file = self.client.files.create(
                file = ("user_health_data.csv", file_obj, "text/csv"),
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
                input = user_input
            )

            for index, out_item in enumerate(response.output):
                if getattr(out_item, "type", None) == "message":
                    content_elements = getattr(out_item, "content", [])
                    for element in content_elements:
                        text = getattr(element, "text", None)
                        if text:
                            logger.info(f"Outcome generated successfully: {text[:100]}...")
                            return text

            raise Exception("No response content received from OpenAI")

        except Exception as e:
            logger.error(f"OpenAI error: {e}")
            raise