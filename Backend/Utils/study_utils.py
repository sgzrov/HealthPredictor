import logging
import uuid
from typing import Optional, Callable, Tuple

from Backend.Database.study_repository import create_study

logger = logging.getLogger(__name__)

# Generate a study id, or use an existing one if provided
def generate_study_id(existing_study_id: Optional[str] = None) -> str:
    if existing_study_id:
        return existing_study_id
    return str(uuid.uuid4())

def setup_study_id(user_id: str, title: str, session, summary_agent, outcome_agent, existing_study_id: Optional[str] = None) -> Tuple[Optional[Callable[[str], None]], Optional[Callable[[str], None]], Optional[str]]:
    study_id = generate_study_id(existing_study_id)

    if existing_study_id:
        logger.info(f"[STUDY] Using existing study_id: {study_id}")
    else:
        study = create_study(session, study_id, user_id, title, "", "")
        logger.info(f"[STUDY] Created new study with study_id: {study_id}, database_id: {study.id}")

    # Create callback functions for saving analysis results. These will be called when analysis is complete to update the study record
    def save_summary(summary: str) -> None:
        logger.info(f"[DEBUG] setup_study_id: save_summary callback created for study_id: {study_id}")
        summary_agent._append_study_summary(study_id, user_id, summary, session)
    def save_outcome(outcome: str) -> None:
        logger.info(f"[DEBUG] setup_study_id: save_outcome callback created for study_id: {study_id}")
        outcome_agent._append_study_outcome(study_id, user_id, outcome, session)

    return save_summary, save_outcome, study_id