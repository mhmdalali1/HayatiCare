"""
models/test_result.py — TestResult ORM model.
"""

from ..extensions import db


class TestResult(db.Model):
    """A single test measurement for a patient."""

    __tablename__ = "test_result"

    result_id            = db.Column(db.Integer, primary_key=True, autoincrement=True)
    patient_id           = db.Column(db.Integer, db.ForeignKey("patient.patient_id"),         nullable=False)
    doctor_id            = db.Column(db.Integer, db.ForeignKey("doctor.doctor_id"),            nullable=False)
    test_id              = db.Column(db.Integer, db.ForeignKey("medical_test.test_id"),        nullable=False)
    secretary_id         = db.Column(db.Integer, db.ForeignKey("secretary.secretary_id"))
    applied_range_id     = db.Column(db.Integer, db.ForeignKey("test_normal_range.range_id"))
    validated_by_user_id = db.Column(db.Integer, db.ForeignKey("user.user_id"))
    result_date          = db.Column(db.DateTime)
    value                = db.Column(db.Numeric(12, 4))
    unit                 = db.Column(db.String(30))
    fasting_state        = db.Column(db.String(20))
    # Statuses: pending, normal, abnormal
    status               = db.Column(db.String(30), default="pending")
    is_flagged           = db.Column(db.Boolean, default=False)
    validation_method    = db.Column(db.String(50))
    validated_at         = db.Column(db.DateTime)
    validation_note      = db.Column(db.Text)
    notes                = db.Column(db.Text)
    created_at           = db.Column(db.DateTime, server_default=db.func.current_timestamp())

    # Relationships
    patient       = db.relationship("Patient",         back_populates="test_results")
    doctor        = db.relationship("Doctor",          back_populates="test_results")
    secretary     = db.relationship("Secretary",       back_populates="test_results")
    test          = db.relationship("MedicalTest",     back_populates="test_results")
    applied_range = db.relationship("TestNormalRange", back_populates="test_results")

    def to_dict(self):
        """Return a dictionary representation."""
        return {
            "result_id":            self.result_id,
            "patient_id":           self.patient_id,
            "doctor_id":            self.doctor_id,
            "test_id":              self.test_id,
            "secretary_id":         self.secretary_id,
            "applied_range_id":     self.applied_range_id,
            "validated_by_user_id": self.validated_by_user_id,
            "result_date":          self.result_date.isoformat()  if self.result_date   else None,
            "value":                float(self.value)             if self.value is not None else None,
            "unit":                 self.unit,
            "fasting_state":        self.fasting_state,
            "status":               self.status,
            "is_flagged":           self.is_flagged,
            "validation_method":    self.validation_method,
            "validated_at":         self.validated_at.isoformat() if self.validated_at  else None,
            "validation_note":      self.validation_note,
            "notes":                self.notes,
            "created_at":           self.created_at.isoformat()   if self.created_at    else None,
            # Joined convenience fields
            "test_name":    self.test.test_name    if self.test    else None,
            "test_code":    self.test.test_code    if self.test    else None,
            "patient_name": (
                f"{self.patient.user.first_name} {self.patient.user.last_name}"
                if self.patient and self.patient.user else None
            ),
            "normal_range": self.applied_range.to_dict() if self.applied_range else None,
        }

    def __repr__(self):
        return f"<TestResult {self.result_id} patient={self.patient_id} flagged={self.is_flagged}>"
