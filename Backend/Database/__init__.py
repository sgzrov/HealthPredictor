from .chat_models import ChatsDB
from .study_models import StudiesDB

from .db import Base, engine

Base.metadata.create_all(
    bind = engine,
    tables = [ChatsDB.__table__, StudiesDB.__table__]
)