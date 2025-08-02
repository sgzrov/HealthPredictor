import logging
import uuid
from typing import Optional, Callable, Tuple

logger = logging.getLogger(__name__)

# Generate a conversation id, or use a an existing one if provided
def generate_conversation_id(existing_conversation_id: Optional[str] = None) -> str:
    if existing_conversation_id:
        return existing_conversation_id
    return str(uuid.uuid4())

def setup_conversation_history(conversation_id: Optional[str],
                               user_input: str,
                               user_id: str,
                               session,
                               chat_agent) -> Tuple[Optional[Callable[[str], None]], Optional[Callable[[str], None]], Optional[str]]:
    original_conversation_id = conversation_id
    conversation_id = generate_conversation_id(conversation_id)
    if original_conversation_id is None:
        logger.info(f"[CONV] Created new conversation_id: {conversation_id}")

    # Save user message to database immediately
    chat_agent._append_user_message(conversation_id, user_id, user_input, session = session)

    # Create callback function for saving assistant response. This will be called when the AI response is complete
    def save_conversation(full_response: str) -> None:
        chat_agent._append_assistant_response(conversation_id, user_id, full_response, session = session)

    # Return None for partial callback since we only save final responses
    return save_conversation, None, conversation_id