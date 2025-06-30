import os
import logging
from fastapi import FastAPI, UploadFile, File, HTTPException, Form
from dotenv import load_dotenv
from pydantic import BaseModel

from chat_agent import ChatAgent
from study_outcome_agent import StudyOutcomeAgent
from study_summary_agent import StudySummaryAgent
from code_interpreter_selector import CodeInterpreterSelector

logging.basicConfig(level = logging.INFO)
logger = logging.getLogger(__name__)

load_dotenv()

app = FastAPI()

api_key = os.getenv("OPENAI_API_KEY")
if not api_key:
    raise ValueError("OPENAI_API_KEY environment variable not set.")

chat_prompt_path = os.path.join(os.path.dirname(__file__), "Prompts", "ChatPrompt.txt")
summary_prompt_path = os.path.join(os.path.dirname(__file__), "Prompts", "SummaryPrompt.txt")
outcome_prompt_path = os.path.join(os.path.dirname(__file__), "Prompts", "OutcomePrompt.txt")
code_interpreter_selector_prompt_path = os.path.join(os.path.dirname(__file__), "Prompts", "CodeInterpreterSelectorPrompt.txt")
simple_chat_prompt_path = os.path.join(os.path.dirname(__file__), "Prompts", "SimpleChatPrompt.txt")

chat_agent = ChatAgent(api_key, prompt_path = chat_prompt_path)
simple_chat_agent = ChatAgent(api_key, prompt_path = simple_chat_prompt_path)
summary_agent = StudySummaryAgent(api_key, prompt_path = summary_prompt_path)
outcome_agent = StudyOutcomeAgent(api_key, prompt_path = outcome_prompt_path)
selector_agent = CodeInterpreterSelector(api_key, prompt_path = code_interpreter_selector_prompt_path)

class SummarizeRequest(BaseModel):
    text: str

class SelectorRequest(BaseModel):
    user_input: str

class SimpleChatRequest(BaseModel):
    user_input: str

@app.post("/analyze-health-data/")
async def analyze_health_data(file: UploadFile = File(...), user_input: str = Form(...)):
    try:
        analysis = chat_agent.analyze_health_data(file.file, user_input)
        logger.info("Health analysis completed.")
        return {"analysis": analysis}
    except Exception as e:
        logger.exception("Health analysis failed.")
        raise HTTPException(status_code = 500, detail = str(e))

@app.post("/generate-outcome/")
async def generate_outcome(file: UploadFile = File(...), user_input: str = Form(...)):
    try:
        outcome = outcome_agent.generate_outcome(file.file, user_input)
        print(f"[DEBUG] Outcome response: {outcome}")  # Ensure outcome response is not None
        return {"outcome": outcome}
    except Exception as e:
        logger.exception("Outcome generation failed.")
        raise HTTPException(status_code = 500, detail = str(e))

@app.post("/summarize-study/")
async def summarize_study(request: SummarizeRequest):
    try:
        summary = summary_agent.summarize(request.text)
        print(f"[DEBUG: Summary response {summary}]") # Ensure summary response is not None
        return {"summary": summary}
    except Exception as e:
        logger.exception("Summary generation failed.")
        raise HTTPException(status_code = 500, detail = str(e))

@app.post("/should-use-code-interpreter/")
async def should_use_code_interpreter(request: SelectorRequest):
    try:
        result = selector_agent.should_use_code_interpreter(request.user_input)
        return {"use_code_interpreter": result}
    except Exception as e:
        logger.exception("Selector failed.")
        raise HTTPException(status_code = 500, detail = str(e))

@app.post("/simple-chat/")
async def simple_chat(request: SimpleChatRequest):
    try:
        response = simple_chat_agent.simple_chat(request.user_input)
        return {"response": response}
    except Exception as e:
        logger.exception("Simple chat failed.")
        raise HTTPException(status_code = 500, detail = str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host = "0.0.0.0", port = 8000)
