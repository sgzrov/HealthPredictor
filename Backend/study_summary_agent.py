import openai
import logging

logger = logging.getLogger(__name__)

class StudySummaryAgent:
    def __init__(self, api_key, prompt_path):
        self.api_key = api_key
        self.model = "gpt-4o-mini"
        self.client = openai.OpenAI(api_key = api_key)

        with open(prompt_path, "r", encoding = "utf-8") as f:
            self.prompt = f.read()

    def summarize(self, text, prompt = None):
        instructions = prompt if prompt is not None else self.prompt

        try:
            logger.info(f"Attempting to summarize text of length: {len(text)}")

            response = self.client.responses.create(
                model=self.model,
                input=f"{instructions}\n\nText to summarize:\n{text}"
            )

            for index, out_item in enumerate(response.output):
                if getattr(out_item, "type", None) == "message":
                    content_elements = getattr(out_item, "content", [])
                    for element in content_elements:
                        text = getattr(element, "text", None)
                        if text:
                            logger.info(f"Summary generated successfully: {text[:100]}...")
                            return text

            raise Exception("No response content received from OpenAI")

        except Exception as e:
            logger.error(f"OpenAI error: {e}")
            raise