"""
models/doctor.py — Doctor profile ORM model.
"""

from ..extensions import db


class Doctor(db.Model):
    """Extended profile for users with the 'doctor' role."""

    __tablename__ = "doctor"

    doctor_id      = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id        = db.Column(db.Integer, db.ForeignKey("user.user_id", ondelete="CASCADE"), nullable=False)
    specialization = db.Column(db.String(100))
    license_number = db.Column(db.String(50), unique=True)
    office_room    = db.Column(db.String(20))
    created_at     = db.Column(db.DateTime, server_default=db.func.current_timestamp())
    updated_at     = db.Column(
        db.DateTime,
        server_default=db.func.current_timestamp(),
        onupdate=db.func.current_timestamp(),
    )

    # Relationships
    user         = db.relationship("User",        back_populates="doctor")
    appointments = db.relationship("Appointment", back_populates="doctor", lazy="dynamic")
    test_results = db.relationship("TestResult",  back_populates="doctor", lazy="dynamic")
    assignments  = db.relationship("PatientDoctorAssignment", back_populates="doctor", lazy="dynamic")

    def to_dict(self):
        """Return a dictionary with all doctor fields including linked user info."""
        return {
            "doctor_id":      self.doctor_id,
            "user_id":        self.user_id,
            "specialization": self.specialization,
            "license_number": self.license_number,
            "office_room":    self.office_room,
            "created_at":     self.created_at.isoformat() if self.created_at else None,
            # Include basic user info
            "first_name": self.user.first_name if self.user else None,
            "last_name":  self.user.last_name  if self.user else None,
            "email":      self.user.email      if self.user else None,
            "phone":      self.user.phone      if self.user else None,
            "is_active":  self.user.is_active  if self.user else None,
        }

    def __repr__(self):
        return f"<Doctor {self.doctor_id} [{self.specialization}]>"
