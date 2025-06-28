import os
import logging
from fastapi import FastAPI, UploadFile, File, HTTPException, Form
from dotenv import load_dotenv
from pydantic import BaseModel

from chat_agent import ChatAgent
from study_outcome_agent import StudyOutcomeAgent
from study_summary_agent import StudySummaryAgent

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

chat_agent = ChatAgent(api_key, prompt_path = chat_prompt_path)
summary_agent = StudySummaryAgent(api_key, prompt_path = summary_prompt_path)
outcome_agent = StudyOutcomeAgent(api_key, prompt_path = outcome_prompt_path)

class SummarizeRequest(BaseModel):
    text: str

@app.post("/analyze-health-data/")
async def analyze_health_data(file: UploadFile = File(...), question: str = Form(...)):
    try:
        analysis = chat_agent.analyze_health_data(file.file, question)
        logger.info("Health analysis completed.")
        return {"analysis": analysis}
    except Exception as e:
        logger.exception("Health analysis failed.")
        raise HTTPException(status_code = 500, detail = str(e))

@app.post("/generate-outcome/")
async def generate_outcome(file: UploadFile = File(...), studytext: str = Form(...)):
    try:
        outcome = outcome_agent.generate_outcome(file.file, studytext)
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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host = "0.0.0.0", port = 8000)
