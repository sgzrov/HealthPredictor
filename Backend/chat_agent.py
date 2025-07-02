import logging
import openai
from typing import BinaryIO, Optional, Tuple

logger = logging.getLogger(__name__)

class ChatAgent:
    def __init__(self, api_key, prompt_path):
        self.api_key = api_key
        self.model = "gpt-4o-mini"
        self.client = openai.OpenAI(api_key = api_key)
        self.conversation_histories = {}

        with open(prompt_path, "r", encoding = "utf-8") as f:
            self.prompt = f.read()

    def _get_history_context(self, conversation_id: Optional[str], latest_user_input: str) -> Tuple[str, list]:
        history = []

        if conversation_id:
            history = self.conversation_histories.get(conversation_id, [])
        history.append({"role": "user", "content": latest_user_input})

        conversation_context = ""
        for turn in history:
            role = "User" if turn["role"] == "user" else "Assistant"
            conversation_context += f"{role}: {turn['content']}\n"
        logger.debug(f"[DEBUG] Conversation context for LLM (conversation_id = {conversation_id}):\n{conversation_context.strip()}")
        return conversation_context.strip(), history

    def simple_chat(self, user_input: str, prompt = None, conversation_id: Optional[str] = None) -> str:
        instructions = prompt if prompt is not None else self.prompt
        conversation_context, history = self._get_history_context(conversation_id, user_input)

        try:
            response = self.client.responses.create(
                model = self.model,
                input = f"{instructions}\nConversation:\n{conversation_context}"
            )

            for index, out_item in enumerate(response.output):
                if getattr(out_item, "type", None) == "message":
                    content_elements = getattr(out_item, "content", [])
                    for element in content_elements:
                        text = getattr(element, "text", None)
                        if text:
                            if conversation_id:
                                history.append({"role": "assistant", "content": text})
                                self.conversation_histories[conversation_id] = history
                            return text

            raise Exception("No response content received from OpenAI")

        except Exception as e:
            logger.error(f"OpenAI error: {e}")
            raise

    def analyze_health_data(self, file_obj: BinaryIO, user_input: str, prompt=None, conversation_id: Optional[str] = None) -> str:
        instructions = prompt if prompt is not None else self.prompt
        conversation_context, history = self._get_history_context(conversation_id, user_input)

        try:
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
                input = conversation_context
            )

            for index, out_item in enumerate(response.output):
                if getattr(out_item, "type", None) == "message":
                    content_elements = getattr(out_item, "content", [])
                    for element in content_elements:
                        text = getattr(element, "text", None)
                        if text:
                            if conversation_id:
                                history.append({"role": "assistant", "content": text})
                                self.conversation_histories[conversation_id] = history
                            return text
            raise Exception("No response content received from OpenAI")
        except Exception as e:
            logger.error(f"OpenAI error: {e}")
            raise
