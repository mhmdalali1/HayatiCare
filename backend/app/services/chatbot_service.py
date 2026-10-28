"""
services/chatbot_service.py — Restricted medical chatbot logic.

The chatbot ONLY answers:
  1. General questions about how to use the application.
  2. Reference ranges for medical tests (from CHATBOT_FAQ_ENTRY).

It NEVER provides clinical diagnoses or specific medical advice.
Responses are found via keyword matching against the FAQ table.
Every query is logged in CHAT_QUERY_LOG.
"""

from ..extensions import db
from ..models.chatbot_faq_entry import ChatbotFaqEntry
from ..models.chat_query_log import ChatQueryLog

# Default response when no FAQ matches the query
_NO_MATCH_RESPONSE = (
    "I'm sorry, I don't have information about that topic. "
    "This chatbot can only answer questions about how to use the HMSS application "
    "and provide reference ranges for medical tests. "
    "Please consult your doctor for medical advice."
)

# Hard disclaimer appended to every response
_DISCLAIMER = (
    "\n\n⚠️ Disclaimer: This chatbot provides reference information only. "
    "It does not provide medical diagnoses or advice. "
    "Always consult a qualified healthcare professional."
)


def _tokenise(text: str) -> set:
    """Return a set of lowercase words from the text, stripped of punctuation."""
    import re
    return set(re.findall(r"[a-z0-9]+", text.lower()))


def handle_query(query_text: str, user_id: int = None):
    """
    Match the query text against active FAQ entries using keyword overlap.

    Algorithm:
      1. Tokenise both the query and each FAQ question.
      2. Compute the Jaccard-like overlap (intersection / query tokens).
      3. Return the FAQ with the highest overlap score (threshold > 0).
      4. Fall back to the no-match response.

    Logs every query and its response in CHAT_QUERY_LOG.

    Returns:
        dict with keys: response_text, faq_id (or None), test_id (or None)
    """
    faqs = ChatbotFaqEntry.query.filter_by(is_active=True).all()

    query_tokens = _tokenise(query_text)
    best_score = 0
    best_faq = None

    for faq in faqs:
        faq_tokens = _tokenise(faq.question)
        if not faq_tokens:
            continue
        overlap = len(query_tokens & faq_tokens) / len(faq_tokens)
        if overlap > best_score:
            best_score = overlap
            best_faq = faq

    if best_faq and best_score > 0.1:
        response_text = best_faq.answer + _DISCLAIMER
        faq_id  = best_faq.faq_id
        test_id = best_faq.test_id
    else:
        response_text = _NO_MATCH_RESPONSE + _DISCLAIMER
        faq_id  = None
        test_id = None

    # Log the interaction
    log_entry = ChatQueryLog(
        user_id=user_id,
        test_id=test_id,
        faq_id=faq_id,
        query_text=query_text,
        response_text=response_text,
    )
    db.session.add(log_entry)
    db.session.commit()

    return {
        "response_text": response_text,
        "faq_id":        faq_id,
        "test_id":       test_id,
    }


def get_available_topics():
    """Return a list of distinct topics from active FAQ entries."""
    rows = (
        db.session.query(ChatbotFaqEntry.topic)
        .filter(ChatbotFaqEntry.is_active == True, ChatbotFaqEntry.topic.isnot(None))
        .distinct()
        .all()
    )
    return [r.topic for r in rows]
