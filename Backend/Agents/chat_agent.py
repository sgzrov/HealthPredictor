import logging
import openai
from typing import BinaryIO, Optional, List, Any, Generator
from dataclasses import dataclass

from Backend.Database.chat_repository import create_chat_message, get_chat_history

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
logger.propagate = True

@dataclass
class Message:
    role: str
    content: str

class ChatAgent:
    def __init__(self, api_key: str, prompt_path: str, model: str = "gpt-4o-mini") -> None:
        self.api_key = api_key
        self.model = model
        self.client = openai.OpenAI(api_key = api_key)
        try:
            with open(prompt_path, "r", encoding = "utf-8") as f:
                self.prompt = f.read()
        except Exception as e:
            logger.error(f"Error reading prompt file: {e}")
            raise

    def _append_user_message(self, conversation_id: str, user_id: str, user_message: str, session) -> None:
        if not conversation_id or not user_message.strip():
            return
        if session is None:
            raise ValueError("A database session must be provided.")
        create_chat_message(session, conversation_id, user_id, "user", user_message.strip())
        logger.info(f"[CONV] User message appended to DB ({conversation_id}, {user_id}): {user_message.strip()}")

    def _append_assistant_response(self, conversation_id: str, user_id: str, full_response: str, session) -> None:
        if not conversation_id or not full_response.strip():
            return
        if session is None:
            raise ValueError("A database session must be provided to ChatAgent methods.")
        create_chat_message(session, conversation_id, user_id, "assistant", full_response.strip())
        logger.info(f"[CONV] Assistant response appended to DB ({conversation_id}, {user_id}): {full_response.strip()}")

    def _get_history_context(self, conversation_id: Optional[str], user_id: Optional[str], session) -> str:
        if not conversation_id or not user_id:
            return ""

        db_history = get_chat_history(session, conversation_id, user_id)
        conversation_context = ""
        for message in db_history:
            role = "User" if message.role == "user" else "Assistant"
            conversation_context += f"{role}: {message.content}\n"
        logger.info(f"[CONV] Context for LLM ({conversation_id}, {user_id}):\n{conversation_context.strip()}")
        return conversation_context.strip()

    def get_conversation_history(self, conversation_id: str, user_id: str, session) -> List[Message]:
        db_history = get_chat_history(session, conversation_id, user_id)
        messages = []
        for m in db_history:
            msg = Message(role = m.role, content = m.content)
            messages.append(msg)
        return messages

    def simple_chat(self, user_input: str, user_id: str, prompt: Optional[str] = None,
                    conversation_id: Optional[str] = None, session = None) -> Generator[Any, None, None]:
        conversation_context = self._get_history_context(conversation_id, user_id, session)
        instructions = prompt if prompt is not None else self.prompt

        try:
            response = self.client.responses.create(
                model = self.model,
                input = f"{instructions}\nConversation:\n{conversation_context}\nUser: {user_input}",
                stream = True
            )
            for chunk in response:
                yield chunk
        except openai.APIError as e:
            logger.error(f"OpenAI API error: {e}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error in simple_chat: {e}")
            raise

    def analyze_health_data(self, file_obj: BinaryIO, user_input: str, user_id: str,
                          prompt: Optional[str] = None, conversation_id: Optional[str] = None,
                          filename: str = "user_health_data.csv", session = None) -> Generator[Any, None, None]:
        conversation_context = self._get_history_context(conversation_id, user_id, session)
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
                input = f"{conversation_context}\nUser: {user_input}",
                stream = True
            )
            for chunk in response:
                yield chunk
        except openai.APIError as e:
            logger.error(f"OpenAI API error: {e}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error in analyze_health_data: {e}")
            raise
