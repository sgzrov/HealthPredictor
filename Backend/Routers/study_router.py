import logging
import uuid
from fastapi import APIRouter, Request, HTTPException

from Backend.Database.db import SessionLocal
from Backend.Database.study_repository import create_study, get_studies_for_user, get_study_by_id
from Backend.auth import verify_clerk_jwt

router = APIRouter(prefix = "/studies", tags = ["studies"])

logger = logging.getLogger(__name__)

# Retrieve all studies for a user
@router.get("/retrieve-user-studies")
def retrieve_user_studies(request: Request):
    user = verify_clerk_jwt(request)
    user_id = user['sub']
    session = SessionLocal()
    try:
        studies = get_studies_for_user(session, user_id)
        logger.info(f"[DEBUG] retrieve_user_studies: Found {len(studies)} studies for user {user_id}")
        result = [
            {
                "id": s.id,
                "study_id": s.study_id,
                "user_id": s.user_id,
                "title": s.title,
                "summary": s.summary,
                "outcome": s.outcome,
                "import_date": s.import_date.isoformat() if s.import_date else None
            }
            for s in studies
        ]
        return result
    finally:
        session.close()
        logger.info("[DEBUG] retrieve_user_studies: Database session closed")

# Retrieve a specific study by study_id
@router.get("/study/{study_id}")
def get_study_by_study_id(study_id: str, request: Request):
    user = verify_clerk_jwt(request)
    user_id = user['sub']
    session = SessionLocal()
    try:
        study = get_study_by_id(session, study_id, user_id)
        if not study:
            return None
        return {
            "id": study.id,
            "study_id": study.study_id,
            "user_id": study.user_id,
            "title": study.title,
            "summary": study.summary,
            "outcome": study.outcome,
            "import_date": study.import_date.isoformat() if study.import_date else None
        }
    finally:
        session.close()

# Add a new study for an authenticated user
@router.post("/add-new-study")
def add_new_study(title: str = '', summary: str = '', outcome: str = '', study_id: str = None, request: Request = None):
    if request is None:
        raise HTTPException(status_code = 400, detail = "Request object is required")

    user = verify_clerk_jwt(request)
    user_id = user['sub']

    # Use provided study_id or generate a new one
    if study_id is None:
        study_id = str(uuid.uuid4())
        logger.info(f"[DEBUG] add_new_study: Generated new study_id: {study_id}")

    session = SessionLocal()
    try:
        study = create_study(session, study_id, user_id, title, summary, outcome)
        result = {
            "id": study.id,
            "study_id": study.study_id,
            "user_id": study.user_id,
            "title": study.title,
            "summary": study.summary,
            "outcome": study.outcome,
            "import_date": study.import_date.isoformat() if study.import_date else None
        }
        return result
    finally:
        session.close()
        logger.info("[DEBUG] add_new_study: Database session closed")