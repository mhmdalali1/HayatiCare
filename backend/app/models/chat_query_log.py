"""
models/chat_query_log.py — ChatQueryLog ORM model.
"""

from ..extensions import db


class ChatQueryLog(db.Model):
    """Records every chatbot query for auditing and improvement."""

    __tablename__ = "chat_query_log"

    chat_log_id   = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id       = db.Column(db.Integer, db.ForeignKey("user.user_id"))
    test_id       = db.Column(db.Integer, db.ForeignKey("medical_test.test_id"))
    faq_id        = db.Column(db.Integer, db.ForeignKey("chatbot_faq_entry.faq_id"))
    query_text    = db.Column(db.Text)
    response_text = db.Column(db.Text)
    created_at    = db.Column(db.DateTime, server_default=db.func.current_timestamp())

    # Relationships
    test = db.relationship("MedicalTest",   back_populates="query_logs")
    faq  = db.relationship("ChatbotFaqEntry", back_populates="query_logs")

    def to_dict(self):
        """Return a dictionary representation."""
        return {
            "chat_log_id":   self.chat_log_id,
            "user_id":       self.user_id,
            "test_id":       self.test_id,
            "faq_id":        self.faq_id,
            "query_text":    self.query_text,
            "response_text": self.response_text,
            "created_at":    self.created_at.isoformat() if self.created_at else None,
        }

    def __repr__(self):
        return f"<ChatQueryLog {self.chat_log_id} user={self.user_id}>"
