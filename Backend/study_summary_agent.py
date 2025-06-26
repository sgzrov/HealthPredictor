import os
from openai import OpenAI

class StudySummaryAgent:
    def __init__(self, api_key, prompt_path = None):
        self.client = OpenAI(api_key = api_key)

        if prompt_path is None:
            prompt_path = os.path.join(os.path.dirname(__file__), "Prompts", "SummaryPrompt.txt")
        with open(prompt_path, "r", encoding = "utf-8") as f:
            self.prompt = f.read()

    def summarize(self, text, prompt = None):
        instructions = prompt if prompt is not None else self.prompt
        response = self.client.responses.create(
            model = "gpt-4.1-mini",
            instructions = instructions,
            input = text
        )

        if hasattr(response, "output_text"):
            return response.output_text

        outputs = []
        for item in getattr(response, "output", []):
            for content in item.get("content", []):
                if content.get("type") == "output_text":
                    outputs.append(content.get("text", ""))
        return "\n".join(outputs)