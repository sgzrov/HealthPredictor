# Use a slim Python image as the base
FROM python:3.11-slim

# Set the working directory inside the container
WORKDIR /app

# Copy requirements and install dependencies
COPY Backend/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy your backend code into the container
COPY Backend /app/Backend

# Expose the port FastAPI will run on
EXPOSE 8000

# Start the app with Gunicorn and Uvicorn workers
CMD ["gunicorn", "-k", "uvicorn.workers.UvicornWorker", "Backend.app:app", "--workers", "4", "--bind", "0.0.0.0:8000", "--timeout", "300"]
