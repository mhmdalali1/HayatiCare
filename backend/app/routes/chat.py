"""
routes/chat.py — AI chat endpoints powered by the RAG pipeline.

POST /api/chat         — full response (no JWT required)
POST /api/chat/stream  — Server-Sent Events streaming (no JWT required)
"""

from flask import Blueprint, request, jsonify, Response, stream_with_context
from ..services.ai_service import ask_ai, ask_ai_stream

chat_bp = Blueprint("chat", __name__, url_prefix="/api")


@chat_bp.route("/chat", methods=["POST"])
def chat():
    data = request.get_json(silent=True) or {}
    question = data.get("question", "").strip()

    if not question:
        return jsonify({"error": "question field is required and must not be empty"}), 400

    try:
        answer = ask_ai(question)
        return jsonify({"answer": answer}), 200
    except Exception as exc:
        return jsonify({"error": f"Unexpected error: {type(exc).__name__}"}), 500


@chat_bp.route("/chat/stream", methods=["POST"])
def chat_stream():
    data = request.get_json(silent=True) or {}
    question = data.get("question", "").strip()

    if not question:
        return jsonify({"error": "question field is required and must not be empty"}), 400

    def generate():
        for chunk in ask_ai_stream(question):
            yield f"data: {chunk}\n\n"
        yield "data: [DONE]\n\n"

    return Response(
        stream_with_context(generate()),
        mimetype="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",
        },
    )
