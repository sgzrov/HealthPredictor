import logging
import uuid
from typing import Optional, Callable, Tuple

logger = logging.getLogger(__name__)

def setup_conversation_history(conversation_id: Optional[str],
                               user_input: str,
                               user_id: str,
                               session,
                               chat_agent) -> Tuple[Optional[Callable[[str], None]], Optional[Callable[[str], None]], Optional[str]]:
    # If no conversation_id, create a new one for this conversation
    if not conversation_id:
        conversation_id = str(uuid.uuid4())
        logger.info(f"[CONV] Created new conversation_id: {conversation_id}")

    # Save user message to database
    chat_agent._append_user_message(conversation_id, user_id, user_input, session = session)

    def save_conversation(full_response: str) -> None:
        chat_agent._append_assistant_response(conversation_id, user_id, full_response, session = session)

    # Return None for partial callback since we only save final responses
    return save_conversation, None, conversation_id