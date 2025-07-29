from .study_models import StudiesDB

# Adds a new study to a user's collection
def create_study(session, user_id, title, summary, outcome):
    study = StudiesDB(
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
    return session.query(StudiesDB).filter_by(user_id = user_id).all()
