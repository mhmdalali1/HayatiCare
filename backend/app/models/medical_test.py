"""
models/medical_test.py — MedicalTest ORM model.
"""

from ..extensions import db


class MedicalTest(db.Model):
    """A type of medical/lab test (e.g., blood glucose, haemoglobin)."""

    __tablename__ = "medical_test"

    test_id      = db.Column(db.Integer, primary_key=True, autoincrement=True)
    test_code    = db.Column(db.String(30), unique=True, nullable=False)
    test_name    = db.Column(db.String(100), nullable=False)
    default_unit = db.Column(db.String(30))
    description  = db.Column(db.Text)
    category     = db.Column(db.String(50))
    is_active    = db.Column(db.Boolean, default=True)
    created_at   = db.Column(db.DateTime, server_default=db.func.current_timestamp())
    updated_at   = db.Column(
        db.DateTime,
        server_default=db.func.current_timestamp(),
        onupdate=db.func.current_timestamp(),
    )

    # Relationships
    normal_ranges = db.relationship("TestNormalRange", back_populates="test",       lazy="dynamic", cascade="all, delete-orphan")
    test_results  = db.relationship("TestResult",      back_populates="test",       lazy="dynamic")
    faq_entries   = db.relationship("ChatbotFaqEntry", back_populates="test",       lazy="dynamic")
    query_logs    = db.relationship("ChatQueryLog",    back_populates="test",       lazy="dynamic")

    def to_dict(self):
        """Return a dictionary representation."""
        return {
            "test_id":      self.test_id,
            "test_code":    self.test_code,
            "test_name":    self.test_name,
            "default_unit": self.default_unit,
            "description":  self.description,
            "category":     self.category,
            "is_active":    self.is_active,
            "created_at":   self.created_at.isoformat() if self.created_at else None,
        }

    def __repr__(self):
        return f"<MedicalTest {self.test_code} — {self.test_name}>"
