import os
import logging
import boto3
import io
from typing import BinaryIO
from datetime import datetime
from botocore.exceptions import ClientError

logger = logging.getLogger(__name__)

class S3Storage:
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

    def upload_health_data_file(self, file_obj: BinaryIO, user_id: str, filename: str) -> str:
        try:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            key = f"users/{user_id}/health_data/{timestamp}_{filename}"  # Generate a unique S3 key for this upload using a timestamp

            # Upload the file to S3
            file_obj.seek(0)
            self.s3_client.upload_fileobj(file_obj, self.bucket_name, key)
            s3_url = f"{self.endpoint_url}/{self.bucket_name}/{key}"
            logger.info(f"Successfully uploaded file to Tigris: {s3_url}")

            # Keep only the latest file for this user
            prefix = f"users/{user_id}/health_data/"
            response = self.s3_client.list_objects_v2(Bucket = self.bucket_name, Prefix = prefix)
            files = response.get('Contents', [])
            files_sorted = sorted(files, key = lambda x: x['Key'], reverse = True)  # Sort files by key (the timestamp in key ensures correct order)
            for file_info in files_sorted[1:]:  # Keep the first (latest), delete the rest
                old_key = file_info['Key']
                self.s3_client.delete_object(Bucket = self.bucket_name, Key = old_key)
                logger.info(f"Deleted old health data file: {old_key}")

            return s3_url
        except ClientError as e:
            logger.error(f"Error uploading file to Tigris: {e}")
            raise Exception(f"Failed to upload file to Tigris: {str(e)}")

    # Download a file from Tigris and return as a file object
    def download_file_from_url(self, s3_url: str) -> BinaryIO:
        try:
            # Validate and extract the S3 object key from the URL
            expected_prefix = f"{self.endpoint_url}/{self.bucket_name}/"
            if not s3_url.startswith(expected_prefix):
                raise Exception(f"Invalid S3 URL format: {s3_url}")
            key = s3_url[len(expected_prefix):]

            # Download the file from S3
            response = self.s3_client.get_object(Bucket=self.bucket_name, Key=key)
            file_content = response['Body'].read()

            file_obj = io.BytesIO(file_content)
            file_obj.seek(0)
            return file_obj
        except ClientError as e:
            logger.error(f"Failed to download file from Tigris: {e}")
            raise Exception(f"Failed to download file from Tigris: {str(e)}")