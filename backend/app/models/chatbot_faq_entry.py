"""
models/chatbot_faq_entry.py — ChatbotFaqEntry ORM model.
"""

from ..extensions import db


class ChatbotFaqEntry(db.Model):
    """A single FAQ entry used by the restricted medical chatbot."""

    __tablename__ = "chatbot_faq_entry"

    faq_id     = db.Column(db.Integer, primary_key=True, autoincrement=True)
    test_id    = db.Column(db.Integer, db.ForeignKey("medical_test.test_id"))
    topic      = db.Column(db.String(100))
    question   = db.Column(db.Text, nullable=False)
    answer     = db.Column(db.Text, nullable=False)
    is_active  = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, server_default=db.func.current_timestamp())
    updated_at = db.Column(
        db.DateTime,
        server_default=db.func.current_timestamp(),
        onupdate=db.func.current_timestamp(),
    )

    # Relationships
    test       = db.relationship("MedicalTest",   back_populates="faq_entries")
    query_logs = db.relationship("ChatQueryLog",  back_populates="faq",  lazy="dynamic")

    def to_dict(self):
        """Return a dictionary representation."""
        return {
            "faq_id":    self.faq_id,
            "test_id":   self.test_id,
            "topic":     self.topic,
            "question":  self.question,
            "answer":    self.answer,
            "is_active": self.is_active,
        }

    def __repr__(self):
        return f"<ChatbotFaqEntry {self.faq_id} topic={self.topic}>"
