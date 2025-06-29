import requests
import logging
from typing import BinaryIO
import os

logger = logging.getLogger(__name__)

class StudyOutcomeAgent:
    def __init__(self, api_key, prompt_path):
        self.api_key = api_key
        self.model = "gpt-4.1-mini"
        self.base_url = "https://api.openai.com/v1"
        self.headers = {"Authorization": f"Bearer {self.api_key}"}

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

            container_payload = {"name": "Outcome Data Container"}
            logger.debug(f"Creating container with payload: {container_payload}")
            container_resp = requests.post(
                f"{self.base_url}/containers",
                headers = {**self.headers, "Content-Type": "application/json"},
                json = container_payload
            )
            container_resp.raise_for_status()
            container_id = container_resp.json()["id"]
            logger.debug(f"Container created with ID: {container_id}")

            files = {"file": ("user_health_data.csv", file_obj, "text/csv")}
            data = {"purpose": "assistants"}
            logger.debug("Uploading CSV file to OpenAI...")
            file_upload_resp = requests.post(
                f"{self.base_url}/files",
                headers = self.headers,
                files = files,
                data = data
            )
            file_upload_resp.raise_for_status()
            file_id = file_upload_resp.json()["id"]
            logger.debug(f"File uploaded with ID: {file_id}")

            container_file_payload = {"file_id": file_id}
            logger.debug(f"Attaching file to container: {container_file_payload}")
            upload_resp = requests.post(
                f"{self.base_url}/containers/{container_id}/files",
                headers = {**self.headers, "Content-Type": "application/json"},
                json = container_file_payload
            )
            upload_resp.raise_for_status()
            logger.debug("File attached to container successfully.")

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
                "instructions": instructions,
                "input": user_input
            }
            logger.info(f"Sending responses payload: {responses_payload}")
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

                if "text" in response_data and response_data["text"]:
                    return response_data["text"]
            except (IndexError, KeyError, TypeError) as e:
                logger.warning(f"Error parsing nested output structure: {e}")

            # Log the full response for debugging if we can't extract text
            logger.error(f"Could not extract text from response. Response keys: {list(response_data.keys())}")
            logger.debug(f"Full response data: {response_data}")

            raise Exception("Outcome generation failed: could not extract response.")

        except Exception as e:
            logger.error(f"OpenAI error: {e}")
            raise