import os
from fastapi import FastAPI, UploadFile, File, HTTPException, Form
from dotenv import load_dotenv
import logging

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

@app.get("/")
def read_root():
    return {"message": "Health Predictor Backend is running..."}

@app.post("/analyze-health-data/")
async def analyze_health_data(file: UploadFile = File(...), question: str = Form(...)):

    if not file_manager.validate_csv_file("user_health_data.csv"):
        raise HTTPException(status_code=400, detail="Invalid file type. Expected a CSV.")

    temp_file_path = None
    openai_file_id = None

    try:
        temp_file_path = file_manager.save_uploaded_file(file, "user_health_data.csv")  # Save uploaded file temporarily
        openai_file_id = health_agent.upload_file(temp_file_path)  # Upload file to OpenAI
        analysis = health_agent.analyze_health_data(openai_file_id, question)  # Analyze health data and provide response to user

        logger.info("Heath analysis completed.")
        return {"analysis": analysis}

    except Exception as e:
        logger.exception("Error occurred during analysis.")
        raise HTTPException(status_code = 500, detail = str(e))

    finally:
        if temp_file_path:
            file_manager.cleanup_file(temp_file_path)  # Clean file path on disk
        if openai_file_id:
            health_agent.cleanup_file(openai_file_id)  # Clean file from OpenAI

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)