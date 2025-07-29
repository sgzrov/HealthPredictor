from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
import io
import logging

from Backend.Database.s3_storage import S3Storage
from Backend.auth import verify_clerk_jwt

router = APIRouter(prefix="/files", tags=["files"])

logger = logging.getLogger(__name__)

@router.post("/upload-health-data/")
async def upload_health_data(file: UploadFile = File(...), user = Depends(verify_clerk_jwt)):
    try:
        s3_storage = S3Storage()
    except ValueError as e:
        logger.warning(f"S3Storage initialization failed: {e}")
        raise HTTPException(status_code = 503, detail = "Tigris storage not configured")

    try:
        user_id = user.get('sub', 'unknown')
        file_bytes = await file.read()
        file_obj = io.BytesIO(file_bytes)

        filename = file.filename or "user_health_data.csv"
        s3_url = s3_storage.upload_health_data_file(file_obj, user_id, filename)

        logger.info(f"Successfully uploaded health data for user {user_id}: {s3_url}")
        return {"s3_url": s3_url, "message": "Health data uploaded successfully"}

    except Exception as e:
        logger.error(f"Error uploading health data: {e}")
        raise HTTPException(status_code = 500, detail = str(e))