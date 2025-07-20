import os
import logging
import boto3
import io

from typing import BinaryIO
from datetime import datetime
from botocore.exceptions import ClientError

logger = logging.getLogger(__name__)

class S3StorageService:
    def __init__(self):
        self.access_key_id = os.getenv("AWS_ACCESS_KEY_ID")
        self.secret_access_key = os.getenv("AWS_SECRET_ACCESS_KEY")
        self.endpoint_url = os.getenv("AWS_ENDPOINT_URL_S3")
        self.region = os.getenv("AWS_REGION", "auto")
        self.bucket_name = os.getenv("TIGRIS_BUCKET_NAME", "healthpredictor-data")

        if not all([self.access_key_id, self.secret_access_key, self.endpoint_url]):
            raise ValueError("Missing required Tigris environment variables")

        self.s3_client = boto3.client(
            's3',
            aws_access_key_id = self.access_key_id,
            aws_secret_access_key = self.secret_access_key,
            endpoint_url = self.endpoint_url,
            region_name = self.region
        )

    # Upload user_health_data.csv to Tigris and return the s3 URL
    def upload_health_data_file(self, file_obj: BinaryIO, user_id: str, filename: str) -> str:
        try:
            # Create a unique key for the file
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            key = f"users/{user_id}/health_data/{timestamp}_{filename}"

            # Upload the file
            file_obj.seek(0)
            self.s3_client.upload_fileobj(file_obj, self.bucket_name, key)

            # Return the S3 URL
            s3_url = f"{self.endpoint_url}/{self.bucket_name}/{key}"
            logger.info(f"Successfully uploaded file to Tigris: {s3_url}")

            return s3_url

        except ClientError as e:
            logger.error(f"Error uploading file to Tigris: {e}")
            raise Exception(f"Failed to upload file to Tigris: {str(e)}")

    def download_health_data_file(self, s3_url: str) -> bytes:
        """
        Download a health data file from Tigris
        """
        try:
            # Extract key from S3 URL
            key = s3_url.replace(f"{self.endpoint_url}/{self.bucket_name}/", "")

            # Download the file
            response = self.s3_client.get_object(Bucket=self.bucket_name, Key=key)
            file_content = response['Body'].read()

            logger.info(f"Successfully downloaded file from Tigris: {s3_url}")
            return file_content

        except ClientError as e:
            logger.error(f"Error downloading file from Tigris: {e}")
            raise Exception(f"Failed to download file from Tigris: {str(e)}")

    def download_file_from_url(self, s3_url: str) -> BinaryIO:
        """
        Download a file from Tigris and return as file object
        """
        try:
            logger.debug(f"Downloading file from URL: {s3_url}")
            logger.debug(f"Endpoint URL: {self.endpoint_url}")
            logger.debug(f"Bucket name: {self.bucket_name}")

            # Extract key from S3 URL
            key = s3_url.replace(f"{self.endpoint_url}/{self.bucket_name}/", "")
            logger.debug(f"Extracted key: {key}")

            # Download the file
            logger.debug(f"Calling S3 get_object with bucket: {self.bucket_name}, key: {key}")
            response = self.s3_client.get_object(Bucket=self.bucket_name, Key=key)
            file_content = response['Body'].read()
            logger.debug(f"Downloaded {len(file_content)} bytes")

            # Return as file object
            file_obj = io.BytesIO(file_content)
            file_obj.seek(0)

            logger.info(f"Successfully downloaded file from Tigris: {s3_url}")
            return file_obj

        except ClientError as e:
            logger.error(f"Error downloading file from Tigris: {e}")
            raise Exception(f"Failed to download file from Tigris: {str(e)}")
        except Exception as e:
            logger.error(f"Unexpected error downloading file: {e}")
            raise Exception(f"Failed to download file: {str(e)}")

    def delete_health_data_file(self, s3_url: str) -> bool:
        """
        Delete a health data file from Tigris
        """
        try:
            # Extract key from S3 URL
            key = s3_url.replace(f"{self.endpoint_url}/{self.bucket_name}/", "")

            # Delete the file
            self.s3_client.delete_object(Bucket=self.bucket_name, Key=key)

            logger.info(f"Successfully deleted file from Tigris: {s3_url}")
            return True

        except ClientError as e:
            logger.error(f"Error deleting file from Tigris: {e}")
            return False