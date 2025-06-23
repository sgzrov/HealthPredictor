import os
import logging
from openai import OpenAI

logger = logging.getLogger(__name__)

class HealthAgent:
    def __init__(self, api_key: str):
        self.client = OpenAI(api_key = api_key)
        self.model = "gpt-4.1-mini"

    def upload_file(self, file_path: str) -> str:
        try:
            with open(file_path, "rb") as f:
                openai_file = self.client.files.create(
                    file=f,
                    purpose="responses_tool"
                )
            logger.info(f"File uploaded to OpenAI with ID: {openai_file.id}")
            return openai_file.id
        except Exception as e:
            logger.error(f"Error uploading file to OpenAI: {e}")
            raise

    def analyze_health_data(self, file_id: str, user_input: str) -> str:
        try:
            response = self.client.responses.create(
                model=self.model,
                tools=[
                    {
                        "type": "code_interpreter",
                        "container": {
                            "type": "auto",
                            "file_ids": [file_id]
                        }
                    }
                ],
                instructions=(
                    "You are a professional health data analyst. Your role is to analyze the provided CSV file "
                    "containing a user's health metric values. When asked a question, write and run Python code "
                    "to analyze the data and provide a clear, data-driven answer."
                ),
                input=user_input
            )

            if hasattr(response, 'output_text') and response.output_text:
                logger.info("Analysis received from Responses API.")
                return response.output_text
            elif hasattr(response, 'output') and isinstance(response.output, str):
                 logger.info("Analysis received from Responses API.")
                 return response.output
            else:
                logger.warning(f"Unexpected response structure from Responses API: {response}")
                raise Exception("Received an unexpected or empty response from the API.")

        except Exception as e:
            logger.error(f"An error occurred calling the Responses API: {e}")
            raise

    def cleanup_file(self, file_id: str):
        try:
            self.client.files.delete(file_id)
            logger.info(f"Cleaned up OpenAI file with ID: {file_id}")
        except Exception as e:
            logger.error(f"Error cleaning up OpenAI file: {e}")
