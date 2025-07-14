import logging
import openai
from typing import BinaryIO, Optional, Dict, List, Any, Generator
from dataclasses import dataclass

logger = logging.getLogger(__name__)

@dataclass
class Message:
    role: str
    content: str

class ChatAgent:
    def __init__(self, api_key: str, prompt_path: str, model: str = "gpt-4o-mini") -> None:
        self.api_key = api_key
        self.model = model
        self.client = openai.OpenAI(api_key=api_key)
        self.conversation_histories: Dict[str, List[Message]] = {}

        try:
            with open(prompt_path, "r", encoding="utf-8") as f:
                self.prompt = f.read()
        except Exception as e:
            logger.error(f"Error reading prompt file: {e}")
            raise

    def _get_history_context(self, conversation_id: Optional[str]) -> str:
        history = self.conversation_histories.get(conversation_id, []) if conversation_id else []
        logger.debug(f"[DEBUG] Building context from history for {conversation_id}: {history}")

        conversation_context = ""
        for message in history:
            role = "User" if message.role == "user" else "Assistant"
            conversation_context += f"{role}: {message.content}\n"

        logger.debug(f"[DEBUG] Conversation context for LLM (conversation_id = {conversation_id}):\n{conversation_context.strip()}")
        return conversation_context.strip()

    def _append_message(self, conversation_id: str, role: str, content: str) -> None:
        if not conversation_id or not content.strip():
            return

        if conversation_id not in self.conversation_histories:
            self.conversation_histories[conversation_id] = []

        message = Message(role=role, content=content.strip())
        self.conversation_histories[conversation_id].append(message)
        logger.debug(f"[DEBUG] After appending {role}: {self.conversation_histories[conversation_id]}")

    def _append_user_message(self, conversation_id: str, user_message: str) -> None:
        self._append_message(conversation_id, "user", user_message)

    def _append_assistant_response(self, conversation_id: str, full_response: str) -> None:
        self._append_message(conversation_id, "assistant", full_response)

    def simple_chat(self, user_input: str, prompt: Optional[str] = None,
                   conversation_id: Optional[str] = None) -> Generator[Any, None, None]:
        conversation_context = self._get_history_context(conversation_id)
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

    def analyze_health_data(self, file_obj: BinaryIO, user_input: str,
                          prompt: Optional[str] = None, conversation_id: Optional[str] = None,
                          filename: str = "user_health_data.csv") -> Generator[Any, None, None]:
        conversation_context = self._get_history_context(conversation_id)
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

    def clear_conversation(self, conversation_id: str) -> None:
        if conversation_id in self.conversation_histories:
            del self.conversation_histories[conversation_id]
            logger.debug(f"[DEBUG] Cleared conversation history for {conversation_id}")

    def get_conversation_history(self, conversation_id: str) -> List[Message]:
        return self.conversation_histories.get(conversation_id, [])
