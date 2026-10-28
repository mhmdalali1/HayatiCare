"""
routes/chatbot.py — Restricted medical chatbot endpoints.

POST /api/chatbot/query  — Patient only
GET  /api/chatbot/faqs   — List available topics
"""

from flask import Blueprint, request
from flask_jwt_extended import get_jwt
from ..services.chatbot_service import handle_query, get_available_topics
from ..utils.decorators import role_required, any_authenticated
from ..utils.responses import success_response, error_response

chatbot_bp = Blueprint("chatbot", __name__, url_prefix="/api/chatbot")


@chatbot_bp.route("/query", methods=["POST"])
@role_required("patient")
def query_chatbot():
    """
    Handle a patient's chatbot query.
    Returns a lookup-based response. Never provides diagnosis or medical advice.
    """
    data    = request.get_json(silent=True) or {}
    claims  = get_jwt()
    user_id = claims.get("user_id")

    query_text = data.get("query", "").strip()
    if not query_text:
        return error_response("query field is required")

    result = handle_query(query_text=query_text, user_id=user_id)
    return success_response(data=result, message="Query processed")


@chatbot_bp.route("/faqs", methods=["GET"])
@any_authenticated()
def list_faq_topics():
    """Return a list of available chatbot topics."""
    topics = get_available_topics()
    return success_response(data={"topics": topics})
