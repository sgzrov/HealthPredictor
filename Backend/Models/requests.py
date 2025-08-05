from typing import Optional
from pydantic import BaseModel

class StudySummaryRequest(BaseModel):
    text: str
    study_id: Optional[str] = None

class CodeInterpreterSelectorRequest(BaseModel):
    user_input: str

class SimpleChatRequest(BaseModel):
    user_input: str
    conversation_id: Optional[str] = None

class ChatWithCIRequest(BaseModel):
    s3_url: str
    user_input: str
    conversation_id: Optional[str] = None

class StudyOutcomeRequest(BaseModel):
    s3_url: str
    text: str
    study_id: Optional[str] = None
