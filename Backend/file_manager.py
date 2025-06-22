import os
import shutil
import logging

logger = logging.getLogger(__name__)

class FileManager:
    def __init__(self, temp_dir: str = "temp"):
        self.temp_dir = temp_dir  # Creates a temp folder for storing CSV file
        self._ensure_temp_dir_exists()  # Makes sure the temp folder exists

    def _ensure_temp_dir_exists(self):
        os.makedirs(self.temp_dir, exist_ok = True)

    def save_uploaded_file(self, uploaded_file, filename: str) -> str:
        temp_file_path = os.path.join(self.temp_dir, filename)

        try:
            with open(temp_file_path, "wb") as buffer:
                shutil.copyfileobj(uploaded_file.file, buffer)

            logger.info(f"File saved temporarily at {temp_file_path}")
            return temp_file_path

        except Exception as e:
            logger.error(f"Error saving uploaded file: {e}")
            raise

    def cleanup_file(self, file_path: str):
        try:
            if os.path.exists(file_path):
                os.remove(file_path)
                logger.info(f"Removed temporary file {file_path}")

        except Exception as e:
            logger.error(f"Error removing temporary file {file_path}: {e}")

    def validate_csv_file(self, filename: str) -> bool:
        if not filename:
            return False
        return filename.lower().endswith('.csv')