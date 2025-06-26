import logging
import requests
from typing import BinaryIO

logger = logging.getLogger(__name__)

class HealthAgent:
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.model = "gpt-4.1-mini"
        self.base_url = "https://api.openai.com/v1"
        self.headers = {"Authorization": f"Bearer {self.api_key}"}

    def analyze_health_data(self, file_obj: BinaryIO, user_input: str) -> str:
        try:
            container_payload = {"name": "Health Data Container"}
            container_resp = requests.post(
                f"{self.base_url}/containers",
                headers = {**self.headers, "Content-Type": "application/json"},
                json = container_payload
            )
            container_resp.raise_for_status()
            container_id = container_resp.json()["id"]

            files = {"file": ("user_health_data.csv", file_obj, "text/csv")}
            data = {"purpose": "assistants"}
            file_upload_resp = requests.post(
                f"{self.base_url}/files",
                headers=self.headers,
                files=files,
                data=data
            )
            file_upload_resp.raise_for_status()
            file_id = file_upload_resp.json()["id"]

            container_file_payload = {"file_id": file_id}
            upload_resp = requests.post(
                f"{self.base_url}/containers/{container_id}/files",
                headers = {**self.headers, "Content-Type": "application/json"},
                json = container_file_payload
            )
            upload_resp.raise_for_status()

            responses_payload = {
                "model": self.model,
                "tools": [
                    {
                        "type": "code_interpreter",
                        "container": {
                            "type": "auto",
                            "file_ids": [file_id]
                        }
                    }
                ],
                "instructions": (
                    "You are a professional health data analyst. Analyze the provided CSV containing a user's "
                    "health metrics. When asked a question, write and run Python code to answer it accurately."
                ),
                "input": user_input
            }
            response = requests.post(
                f"{self.base_url}/responses",
                headers = {**self.headers, "Content-Type": "application/json"},
                json = responses_payload
            )
            response.raise_for_status()

            response_data = response.json()
            logger.debug(f"Response structure: {response_data.keys()}")
            try:
                if "output" in response_data and response_data["output"]:
                    output = response_data["output"][0]
                    if "content" in output and output["content"]:
                        content = output["content"][0]
                        if content.get("type") == "output_text" and content.get("text"):
                            return content["text"]
                        else:
                            logger.warning(f"Unexpected content type: {content.get('type')}")
            except (IndexError, KeyError, TypeError) as e:
                logger.warning(f"Error parsing nested output structure: {e}")

            if "text" in response_data and response_data["text"]:
                return response_data["text"]

            # Log the full response for debugging if we can't extract text
            logger.error(f"Could not extract text from response. Response keys: {list(response_data.keys())}")
            logger.debug(f"Full response data: {response_data}")

            return "I've received your health data, but couldn't process the response properly."

        except Exception as e:
            logger.error(f"OpenAI error: {e}")
            raise
