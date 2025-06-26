import os
import logging
from fastapi import FastAPI, UploadFile, File, HTTPException, Form
from dotenv import load_dotenv

from health_agent import HealthAgent

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

load_dotenv()

app = FastAPI()

api_key = os.getenv("OPENAI_API_KEY")
if not api_key:
    raise ValueError("OPENAI_API_KEY environment variable not set.")

health_agent = HealthAgent(api_key)

@app.get("/")
def read_root():
    return {"message": "Health Predictor Backend is running."}

@app.post("/analyze-health-data/")
async def analyze_health_data(file: UploadFile = File(...), question: str = Form(...)):
    if not file.filename or not file.filename.lower().endswith(".csv"):
        raise HTTPException(status_code = 400, detail = "Invalid file type. Expected a CSV.")

    try:
        analysis = health_agent.analyze_health_data(file.file, question)
        logger.info("Health analysis completed.")
        return {"analysis": analysis}
    except Exception as e:
        logger.exception("Health analysis failed.")
        raise HTTPException(status_code = 500, detail = str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
