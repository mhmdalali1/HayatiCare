"""
models/body_health.py — BodyHealth ORM model for patient physical health data.
"""

from ..extensions import db
from datetime import datetime


class BodyHealth(db.Model):
    """Stores patient body health metrics including BMI and calorie limits."""

    __tablename__ = "body_health"

    body_health_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    patient_id = db.Column(
        db.Integer, db.ForeignKey("patient.patient_id", ondelete="CASCADE"), nullable=False
    )
    gender = db.Column(db.String(10))  # 'male' or 'female'
    height_cm = db.Column(db.Numeric(5, 2))
    weight_kg = db.Column(db.Numeric(5, 2))
    bmi = db.Column(db.Numeric(4, 2))
    bmi_category = db.Column(db.String(30))
    daily_calorie_limit = db.Column(db.Integer)
    last_updated = db.Column(
        db.DateTime,
        server_default=db.func.current_timestamp(),
        onupdate=db.func.current_timestamp(),
    )

    # Relationships
    patient = db.relationship("Patient", back_populates="body_health_records")

    def to_dict(self):
        """Return a dictionary representation."""
        return {
            "body_health_id": self.body_health_id,
            "patient_id": self.patient_id,
            "gender": self.gender,
            "height_cm": float(self.height_cm) if self.height_cm else None,
            "weight_kg": float(self.weight_kg) if self.weight_kg else None,
            "bmi": float(self.bmi) if self.bmi else None,
            "bmi_category": self.bmi_category,
            "daily_calorie_limit": self.daily_calorie_limit,
            "last_updated": self.last_updated.isoformat() if self.last_updated else None,
        }

    def __repr__(self):
        return f"<BodyHealth {self.body_health_id} patient={self.patient_id} bmi={self.bmi}>"
