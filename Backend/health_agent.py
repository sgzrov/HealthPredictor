# health_agent.py
import logging
from openai import OpenAI
from typing import BinaryIO

logger = logging.getLogger(__name__)

class HealthAgent:
    def __init__(self, api_key: str):
        self.client = OpenAI(api_key=api_key)
        self.model = "gpt-4o"

    def analyze_health_data(self, file_obj: BinaryIO, user_input: str) -> str:
        try:
            uploaded_file = self.client.files.create(
                file=file_obj,
                purpose="assistants"
            )

            response = self.client.responses.create(
                model=self.model,
                tools=[
                    {
                        "type": "code_interpreter",
                        "container": {
                            "type": "auto",
                            "file_ids": [uploaded_file.id]
                        }
                    }
                ],
                instructions=(
                    "You are a professional health data analyst. Analyze the provided CSV containing a user's "
                    "health metrics. When asked a question, write and run Python code to answer it accurately."
                ),
                input=user_input
            )

            return response.output_text

        except Exception as e:
            logger.error(f"OpenAI error: {e}")
            raise
