import os
from fastapi import FastAPI, UploadFile, File, HTTPException, Form
from pydantic import BaseModel
from dotenv import load_dotenv
import logging
from typing import Optional

from health_agent import HealthAgent
from file_manager import FileManager

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

load_dotenv()

app = FastAPI()

api_key = os.getenv("OPENAI_API_KEY")
if not api_key:
    raise ValueError("OPENAI_API_KEY environment variable not set.")

health_agent = HealthAgent(api_key)
file_manager = FileManager()

class HealthAnalysisRequest(BaseModel):
    question: Optional[str] = None

@app.get("/")
def read_root():
    return {"message": "Health Predictor Backend is running"}

@app.post("/analyze-health-data/")
async def analyze_health_data(
    file: UploadFile = File(...),
    question: Optional[str] = Form(None)
):
    """Analyze health data from uploaded CSV file with optional user question."""

    # Validate file
    if not file.filename:
        raise HTTPException(status_code=400, detail="Filename not provided.")

    if not file_manager.validate_csv_file(file.filename):
        raise HTTPException(status_code=400, detail="Invalid file type. Please upload a CSV file.")

    temp_file_path = None
    openai_file_id = None

    try:
        # Save the uploaded file temporarily
        temp_file_path = file_manager.save_uploaded_file(file, file.filename)

        # Upload file to OpenAI
        openai_file_id = health_agent.upload_file(temp_file_path)

        # Analyze the health data
        analysis = health_agent.analyze_health_data(openai_file_id, question)

        logger.info("Health data analysis completed successfully.")
        return {"analysis": analysis}

    except Exception as e:
        logger.exception("An error occurred during analysis.")
        raise HTTPException(status_code=500, detail=str(e))

    finally:
        # Clean up resources
        if temp_file_path:
            file_manager.cleanup_file(temp_file_path)

        if openai_file_id:
            health_agent.cleanup_file(openai_file_id)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)