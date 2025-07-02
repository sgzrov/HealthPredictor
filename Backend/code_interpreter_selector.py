import openai
import logging

logger = logging.getLogger(__name__)

class CodeInterpreterSelector:
    def __init__(self, api_key, prompt_path):
        self.api_key = api_key
        self.model = "gpt-4o-mini"
        self.client = openai.OpenAI(api_key = api_key)

        with open(prompt_path, "r", encoding = "utf-8") as f:
            self.prompt = f.read()

    def should_use_code_interpreter(self, user_input: str, prompt = None) -> str:
        instructions = prompt if prompt is not None else self.prompt

        try:
            response = self.client.responses.create(
                model = self.model,
                input = f"{instructions}\n User input: {user_input}"
            )

            for index, out_item in enumerate(response.output):
                if getattr(out_item, "type", None) == "message":
                    content_elements = getattr(out_item, "content", [])
                    for element in content_elements:
                        text = getattr(element, "text", None)
                        if text:
                            answer = text.strip().lower()
                            logger.info(f"Code interpreter selection response: {answer}")
                            return "yes" if "yes" in answer else "no"

            raise Exception("No response content received from OpenAI")

        except Exception as e:
            logger.error(f"OpenAI error: {e}")
            raise