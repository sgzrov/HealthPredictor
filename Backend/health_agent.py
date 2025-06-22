import os
import logging
from openai import OpenAI
from typing import Optional

logger = logging.getLogger(__name__)

class HealthAgent:
    def __init__(self, api_key: str):
        self.client = OpenAI(api_key=api_key)
        self.assistant = None
        self.assistant_name = "Agent 007"
        self.assistant_instructions = ("You are a health data analyst. Your role is to analyze the provided CSV file containing the user's health metric values. The CSV file has dates as rows and health metrics as columns. When the user asks a question, use the file to answer it.")
        self._load_or_create_assistant()

    # Load assistant from .env or create a new one and update .env
    def _load_or_create_assistant(self):
        env_path = ".env"
        assistant_id = os.getenv("ASSISTANT_ID")

        if assistant_id:
            try:
                self.assistant = self.client.beta.assistants.retrieve(assistant_id)
                logger.info(f"Loaded existing assistant with ID: {assistant_id}")
                return
            except Exception as e:
                logger.warning(f"Stored assistant ID is invalid. Recreating. Reason: {e}")

        # If no valid assistant ID, create a new one
        self.assistant = self.client.beta.assistants.create(
            name = self.assistant_name,
            instructions = self.assistant_instructions,
            model = "gpt-4.1-mini",
            tools = [{"type": "code_interpreter"}]
        )
        logger.info(f"Created new assistant with ID: {self.assistant.id}")
        self._write_assistant_id_to_env(self.assistant.id, env_path)  # Save new ASSISTANT_ID to the .env file

    # Write or update ASSISTANT_ID in the .env file
    def _write_assistant_id_to_env(self, assistant_id: str, env_path: str):
        lines = []
        found = False

        if os.path.exists(env_path):
            with open(env_path, "r") as f:
                lines = f.readlines()

        with open(env_path, "w") as f:
            for line in lines:
                if line.startswith("ASSISTANT_ID="):
                    f.write(f"ASSISTANT_ID={assistant_id}\n")
                    found = True
                else:
                    f.write(line)
            if not found:
                f.write(f"ASSISTANT_ID={assistant_id}\n")

        logger.info("Updated .env with new ASSISTANT_ID")

    # Upload file to OpenAI and return the file ID
    def upload_file(self, file_path: str) -> str:
        try:
            with open(file_path, "rb") as f:
                openai_file = self.client.files.create(
                    file = f,
                    purpose = 'assistants'
                )
            logger.info(f"File uploaded to OpenAI with ID: {openai_file.id}")
            return openai_file.id

        except Exception as e:
            logger.error(f"Error uploading file: {e}")
            raise

    def analyze_health_data(self, file_id: str, question: str) -> str:
        assert self.assistant is not None, "Assistant could not be initialized."

        thread = None
        try:
            initial_message = f"Please scan through the attached CSV file and provide an answer to this input: {question}"

            # Create initial thread
            thread = self.client.beta.threads.create(
                messages=[
                    {
                        "role": "user",
                        "content": initial_message,
                        "attachments": [
                            {"file_id": file_id, "tools": [{"type": "code_interpreter"}]}
                        ]
                    }
                ]
            )
            logger.info(f"Thread created with ID: {thread.id}")

            # Run and poll the thread
            run = self.client.beta.threads.runs.create_and_poll(
                thread_id = thread.id,
                assistant_id = self.assistant.id,
            )
            logger.info(f"Run completed with status: {run.status}")

            if run.status == 'completed':
                messages = self.client.beta.threads.messages.list(
                    thread_id = thread.id,
                    order = "asc"
                )

                # Extract the assistant's response
                assistant_response = ""
                assistant_msg = next((m for m in reversed(messages.data) if m.role == "assistant"), None)
                if assistant_msg:
                    for part in assistant_msg.content:
                        if part.type == "text":
                            assistant_response += getattr(part.text, "value", "")

                logger.info("Run completed and response retrieved.")
                return assistant_response

            else:
                logger.error(f"Run failed with status: {run.status}")
                raise Exception(f"Analysis failed with status: {run.status}")

        except Exception as e:
            logger.error(f"Error during analysis: {e}")
            raise

        finally:
            if thread:
                try:
                    self.client.beta.threads.delete(thread.id)
                    logger.info(f"Thread {thread.id} deleted.")
                except Exception as e:
                    logger.error(f"Error during thread cleanup: {e}")

    def cleanup_file(self, file_id: str):
        try:
            self.client.files.delete(file_id)
            logger.info(f"OpenAI file {file_id} deleted.")
        except Exception as e:
            logger.error(f"Error during OpenAI file cleanup: {e}")
