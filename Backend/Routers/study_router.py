import logging
from fastapi import APIRouter, Request

from Backend.Database.db import SessionLocal
from Backend.Database.study_repository import create_study, get_studies_for_user
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
        return [
            {
                "id": s.id,
                "user_id": s.user_id,
                "title": s.title,
                "summary": s.summary,
                "outcome": s.outcome,
                "import_date": s.import_date.isoformat() if s.import_date else None
            }
            for s in studies
        ]
    finally:
        session.close()

# Add a new study for an authenticated user
@router.post("/add-new-study")
def add_new_study(title: str = '', summary: str = '', outcome: str = '', request: Request = None):
    user = verify_clerk_jwt(request)
    user_id = user['sub']
    session = SessionLocal()
    try:
        study = create_study(session, user_id, title, summary, outcome)
        response = {
            "id": study.id,
            "user_id": study.user_id,
            "title": study.title,
            "summary": study.summary,
            "outcome": study.outcome,
            "import_date": study.import_date.isoformat() if study.import_date else None
        }
        return response
    finally:
        session.close()