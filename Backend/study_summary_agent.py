import requests
import logging

logger = logging.getLogger(__name__)

class StudySummaryAgent:
    def __init__(self, api_key, prompt_path):
        self.api_key = api_key
        self.model = "gpt-4.1-mini"
        self.base_url = "https://api.openai.com/v1"
        self.headers = {"Authorization": f"Bearer {self.api_key}"}

        with open(prompt_path, "r", encoding = "utf-8") as f:
            self.prompt = f.read()

    def summarize(self, text, prompt = None):
        instructions = prompt if prompt is not None else self.prompt
        payload = {
            "model": self.model,
            "instructions": instructions,
            "input": text
        }
        try:
            logger.info(f"Attempting to summarize text of length: {len(text)}")
            response = requests.post(
                f"{self.base_url}/responses",
                headers = {**self.headers, "Content-Type": "application/json"},
                json = payload
            )
            response.raise_for_status()

            data = response.json()
            logger.info(f"Response received: {data}")

            if "output" in data and data["output"]:
                output = data["output"][0]
                if "content" in output and output["content"]:
                    content = output["content"][0]
                    if content.get("type") == "output_text" and content.get("text"):
                        return content["text"]

            raise Exception("Summary generation failed: could not extract response.")

        except Exception as e:
            logger.error(f"OpenAI error: {e}")
            raise