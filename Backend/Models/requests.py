from typing import Optional
from pydantic import BaseModel

class SummarizeRequest(BaseModel):
    text: str

class SelectorRequest(BaseModel):
    user_input: str

class SimpleChatRequest(BaseModel):
    user_input: str
    conversation_id: Optional[str] = None

class ChatWithCIRequest(BaseModel):
    s3_url: str
    user_input: str
    conversation_id: Optional[str] = None

class GenerateOutcomeRequest(BaseModel):
    s3_url: str
    user_input: str