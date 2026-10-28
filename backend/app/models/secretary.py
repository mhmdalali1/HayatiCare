"""
models/secretary.py — Secretary profile ORM model.
"""

from ..extensions import db


class Secretary(db.Model):
    """Extended profile for users with the 'secretary' role."""

    __tablename__ = "secretary"

    secretary_id  = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id       = db.Column(db.Integer, db.ForeignKey("user.user_id", ondelete="CASCADE"), nullable=False)
    employee_code = db.Column(db.String(30), unique=True)
    created_at    = db.Column(db.DateTime, server_default=db.func.current_timestamp())
    updated_at    = db.Column(
        db.DateTime,
        server_default=db.func.current_timestamp(),
        onupdate=db.func.current_timestamp(),
    )

    # Relationships
    user         = db.relationship("User",        back_populates="secretary")
    appointments = db.relationship("Appointment", back_populates="secretary", lazy="dynamic")
    test_results = db.relationship("TestResult",  back_populates="secretary", lazy="dynamic")

    def to_dict(self):
        """Return a dictionary representation."""
        return {
            "secretary_id":  self.secretary_id,
            "user_id":       self.user_id,
            "employee_code": self.employee_code,
            "created_at":    self.created_at.isoformat() if self.created_at else None,
            # Include basic user info
            "first_name": self.user.first_name if self.user else None,
            "last_name":  self.user.last_name  if self.user else None,
            "email":      self.user.email      if self.user else None,
            "phone":      self.user.phone      if self.user else None,
            "is_active":  self.user.is_active  if self.user else None,
        }

    def __repr__(self):
        return f"<Secretary {self.secretary_id} [{self.employee_code}]>"
