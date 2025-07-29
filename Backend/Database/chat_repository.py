from .chat_models import ChatsDB

# Adds a new message to a user's conversation
def create_chat_message(session, conversation_id, user_id, role, content):
    msg = ChatsDB(
        conversation_id = conversation_id,
        user_id = user_id,
        role = role,
        content = content
    )
    session.add(msg)
    session.commit()
    session.refresh(msg)
    return msg

# Retrieves all messages for a user's conversation
def get_chat_history(session, conversation_id, user_id):
    return session.query(ChatsDB).filter_by(conversation_id = conversation_id, user_id = user_id).order_by(ChatsDB.timestamp).all()