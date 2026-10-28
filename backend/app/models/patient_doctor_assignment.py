"""
models/patient_doctor_assignment.py — Links patients to their assigned doctors.
"""

from ..extensions import db


class PatientDoctorAssignment(db.Model):
    """Tracks which doctors are assigned to which patients."""

    __tablename__ = "patient_doctor_assignment"

    assignment_id      = db.Column(db.Integer, primary_key=True, autoincrement=True)
    patient_id         = db.Column(db.Integer, db.ForeignKey("patient.patient_id"), nullable=False)
    doctor_id          = db.Column(db.Integer, db.ForeignKey("doctor.doctor_id"),   nullable=False)
    created_by_user_id = db.Column(db.Integer, db.ForeignKey("user.user_id"),       nullable=False)
    assigned_at        = db.Column(db.DateTime, server_default=db.func.current_timestamp())
    start_date         = db.Column(db.Date)
    end_date           = db.Column(db.Date)
    is_active          = db.Column(db.Boolean, default=True)
    assignment_note    = db.Column(db.Text)

    # Relationships
    patient = db.relationship("Patient", back_populates="assignments")
    doctor  = db.relationship("Doctor",  back_populates="assignments")

    def to_dict(self):
        """Return a dictionary representation."""
        return {
            "assignment_id":      self.assignment_id,
            "patient_id":         self.patient_id,
            "doctor_id":          self.doctor_id,
            "created_by_user_id": self.created_by_user_id,
            "assigned_at":        self.assigned_at.isoformat() if self.assigned_at else None,
            "start_date":         self.start_date.isoformat()  if self.start_date  else None,
            "end_date":           self.end_date.isoformat()    if self.end_date    else None,
            "is_active":          self.is_active,
            "assignment_note":    self.assignment_note,
        }

    def __repr__(self):
        return f"<Assignment patient={self.patient_id} doctor={self.doctor_id}>"
