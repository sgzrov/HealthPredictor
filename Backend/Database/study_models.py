from sqlalchemy import Column, Integer, String, Text, DateTime, func

from .db import Base

class StudiesDB(Base):
    __tablename__ = 'user_studies_data'  # Name of the table
    id = Column(Integer, primary_key = True, autoincrement = True)
    user_id = Column(String(64), index = True, nullable = False)
    title = Column(String(256), nullable = False)
    summary = Column(Text, nullable = True)
    outcome = Column(Text, nullable = True)
    import_date = Column(DateTime(timezone = True), server_default = func.now())
