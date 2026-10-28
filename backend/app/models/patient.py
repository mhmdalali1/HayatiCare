"""
models/patient.py — Patient profile ORM model.
"""

from ..extensions import db


class Patient(db.Model):
    """Extended profile for users with the 'patient' role."""

    __tablename__ = "patient"

    patient_id              = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id                 = db.Column(db.Integer, db.ForeignKey("user.user_id", ondelete="CASCADE"), nullable=False)
    patient_code            = db.Column(db.String(30), unique=True, nullable=False)
    national_id             = db.Column(db.String(30), unique=True)
    date_of_birth           = db.Column(db.Date)
    gender                  = db.Column(db.String(10))
    address                 = db.Column(db.Text)
    blood_type              = db.Column(db.String(5))
    allergies               = db.Column(db.Text)
    chronic_conditions      = db.Column(db.Text)
    insurance_provider      = db.Column(db.String(100))
    insurance_number        = db.Column(db.String(50))
    emergency_contact_name  = db.Column(db.String(100))
    emergency_contact_phone = db.Column(db.String(20))
    created_at              = db.Column(db.DateTime, server_default=db.func.current_timestamp())
    updated_at              = db.Column(
        db.DateTime,
        server_default=db.func.current_timestamp(),
        onupdate=db.func.current_timestamp(),
    )

    # Relationships
    user         = db.relationship("User",        back_populates="patient")
    appointments = db.relationship("Appointment", back_populates="patient", lazy="dynamic")
    test_results = db.relationship("TestResult",  back_populates="patient", lazy="dynamic")
    assignments  = db.relationship("PatientDoctorAssignment", back_populates="patient", lazy="dynamic")
    body_health_records = db.relationship("BodyHealth", back_populates="patient", lazy="dynamic")

    def to_dict(self):
        """Return a dictionary with all patient fields including linked user info."""
        return {
            "patient_id":              self.patient_id,
            "user_id":                 self.user_id,
            "patient_code":            self.patient_code,
            "national_id":             self.national_id,
            "date_of_birth":           self.date_of_birth.isoformat() if self.date_of_birth else None,
            "gender":                  self.gender,
            "address":                 self.address,
            "blood_type":              self.blood_type,
            "allergies":               self.allergies,
            "chronic_conditions":      self.chronic_conditions,
            "insurance_provider":      self.insurance_provider,
            "insurance_number":        self.insurance_number,
            "emergency_contact_name":  self.emergency_contact_name,
            "emergency_contact_phone": self.emergency_contact_phone,
            "created_at":              self.created_at.isoformat() if self.created_at else None,
            # Include basic user info
            "first_name": self.user.first_name if self.user else None,
            "last_name":  self.user.last_name  if self.user else None,
            "email":      self.user.email      if self.user else None,
            "phone":      self.user.phone      if self.user else None,
            "is_active":  self.user.is_active  if self.user else None,
        }

    def __repr__(self):
        return f"<Patient {self.patient_id} [{self.patient_code}]>"
