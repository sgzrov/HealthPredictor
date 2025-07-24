from sqlalchemy import Column, Integer, String, Text, DateTime, func
from .db_session import engine, SessionLocal, Base
import logging

class ChatMessageDB(Base):
    __tablename__ = 'chat_messages'
    id = Column(Integer, primary_key = True, autoincrement = True)
    conversation_id = Column(String(64), index = True, nullable = False)
    user_id = Column(String(64), index = True, nullable = False)
    role = Column(String(16), nullable = False)
    content = Column(Text, nullable = False)
    timestamp = Column(DateTime(timezone = True), server_default = func.now())

def create_tables():
    Base.metadata.create_all(bind = engine)

def add_chat_message(conversation_id, user_id, role, content):
    print(f"[PRINT][DB] INSERT: conv_id={conversation_id}, user_id={user_id}, role={role}, content={content[:100]}")
    import logging
    logger = logging.getLogger("chat_history")
    session = SessionLocal()

    try:
        msg = ChatMessageDB(conversation_id = conversation_id, user_id = user_id, role = role, content = content)
        session.add(msg)
        session.commit()
        session.refresh(msg)
        logger.info(f"[DB] INSERT: conv_id={conversation_id}, user_id={user_id}, role={role}, content={content[:100]}")
        return msg
    finally:
        session.close()

def get_chat_history(conversation_id, user_id):
    session = SessionLocal()

    try:
        return session.query(ChatMessageDB).filter_by(conversation_id = conversation_id, user_id = user_id).order_by(ChatMessageDB.timestamp).all()
    finally:
        session.close()

def get_all_conversation_ids(user_id):
    session = SessionLocal()

    try:
        return [row[0] for row in session.query(ChatMessageDB.conversation_id).filter_by(user_id = user_id).distinct().all()]
    finally:
        session.close()

def upsert_chat_message(conversation_id, user_id, role, content):
    print(f"[PRINT][DB] UPSERT: conv_id={conversation_id}, user_id={user_id}, role={role}, content={content[:100]}")
    import logging
    logger = logging.getLogger("chat_history")
    session = SessionLocal()
    try:
        # Only upsert for assistant role
        if role != "assistant":
            print(f"[PRINT][DB] UPSERT (delegated to add): conv_id={conversation_id}, user_id={user_id}, role={role}, content={content[:100]}")
            logger.info(f"[DB] UPSERT (delegated to add): conv_id={conversation_id}, user_id={user_id}, role={role}, content={content[:100]}")
            return add_chat_message(conversation_id, user_id, role, content)
        # Find the latest assistant message for this conversation and user
        msg = session.query(ChatMessageDB).filter_by(conversation_id=conversation_id, user_id=user_id, role="assistant").order_by(ChatMessageDB.timestamp.desc()).first()
        if msg:
            msg.content = content
            session.commit()
            session.refresh(msg)
            print(f"[PRINT][DB] UPDATE: conv_id={conversation_id}, user_id={user_id}, role={role}, content={content[:100]}")
            logger.info(f"[DB] UPDATE: conv_id={conversation_id}, user_id={user_id}, role={role}, content={content[:100]}")
            return msg
        else:
            print(f"[PRINT][DB] UPSERT (insert): conv_id={conversation_id}, user_id={user_id}, role={role}, content={content[:100]}")
            logger.info(f"[DB] UPSERT (insert): conv_id={conversation_id}, user_id={user_id}, role={role}, content={content[:100]}")
            # No assistant message yet, insert new
            return add_chat_message(conversation_id, user_id, role, content)
    finally:
        session.close()

def get_conversation_last_message_times(user_id):
    session = SessionLocal()
    try:
        results = (
            session.query(
                ChatMessageDB.conversation_id,
                func.max(ChatMessageDB.timestamp).label("last_message_at")
            )
            .filter_by(user_id=user_id)
            .group_by(ChatMessageDB.conversation_id)
            .order_by(func.max(ChatMessageDB.timestamp).desc())
            .all()
        )
        return [
            {"conversation_id": row[0], "last_message_at": row[1].isoformat() if row[1] else None}
            for row in results
        ]
    finally:
        session.close()