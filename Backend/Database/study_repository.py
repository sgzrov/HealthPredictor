from .study_models import StudiesDB

# Add a new study to a user's collection
def create_study(session, study_id, user_id, title, summary, outcome):
    study = StudiesDB(
        study_id = study_id,
        user_id = user_id,
        title = title,
        summary = summary,
        outcome = outcome
    )
    session.add(study)
    session.commit()
    session.refresh(study)
    return study

# Retrieves all studies for a user
def get_studies_for_user(session, user_id):
    studies = session.query(StudiesDB).filter_by(user_id = user_id).all()
    return studies

# Retrieves a specific study by study_id and user_id
def get_study_by_id(session, study_id, user_id):
    return session.query(StudiesDB).filter_by(study_id = study_id, user_id = user_id).first()

# Update study summary by study_id
def update_study_summary_by_id(session, study_id, summary, user_id=None):
    query = session.query(StudiesDB).filter_by(study_id = study_id)
    if user_id:
        query = query.filter_by(user_id = user_id)
    study = query.first()
    if study:
        study.summary = summary
        session.commit()

# Update study outcome by study_id
def update_study_outcome_by_id(session, study_id, outcome, user_id=None):
    query = session.query(StudiesDB).filter_by(study_id = study_id)
    if user_id:
        query = query.filter_by(user_id = user_id)
    study = query.first()
    if study:
        study.outcome = outcome
        session.commit()
