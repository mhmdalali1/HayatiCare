"""
models/appointment.py — Appointment ORM model.
"""

from ..extensions import db


class Appointment(db.Model):
    """A scheduled meeting between a patient and a doctor."""

    __tablename__ = "appointment"

    appointment_id          = db.Column(db.Integer, primary_key=True, autoincrement=True)
    patient_id              = db.Column(db.Integer, db.ForeignKey("patient.patient_id"),   nullable=False)
    doctor_id               = db.Column(db.Integer, db.ForeignKey("doctor.doctor_id"),     nullable=False)
    created_by_user_id      = db.Column(db.Integer, db.ForeignKey("user.user_id"),         nullable=False)
    created_by_role         = db.Column(db.String(20))
    managed_by_secretary_id = db.Column(db.Integer, db.ForeignKey("secretary.secretary_id"))
    requested_at            = db.Column(db.DateTime, server_default=db.func.current_timestamp())
    scheduled_start         = db.Column(db.DateTime)
    scheduled_end           = db.Column(db.DateTime)
    # Valid statuses: pending, confirmed, rescheduled, cancelled, completed
    status                  = db.Column(db.String(30), default="pending")
    reason                  = db.Column(db.Text)
    location                = db.Column(db.String(100))
    secretary_comment       = db.Column(db.Text)
    updated_at              = db.Column(
        db.DateTime,
        server_default=db.func.current_timestamp(),
        onupdate=db.func.current_timestamp(),
    )

    # Relationships
    patient   = db.relationship("Patient",   back_populates="appointments")
    doctor    = db.relationship("Doctor",    back_populates="appointments")
    secretary = db.relationship("Secretary", back_populates="appointments")

    def to_dict(self):
        """Return a dictionary representation."""
        return {
            "appointment_id":          self.appointment_id,
            "patient_id":              self.patient_id,
            "doctor_id":               self.doctor_id,
            "created_by_user_id":      self.created_by_user_id,
            "created_by_role":         self.created_by_role,
            "managed_by_secretary_id": self.managed_by_secretary_id,
            "requested_at":            self.requested_at.isoformat()    if self.requested_at   else None,
            "scheduled_start":         self.scheduled_start.isoformat() if self.scheduled_start else None,
            "scheduled_end":           self.scheduled_end.isoformat()   if self.scheduled_end   else None,
            "status":                  self.status,
            "reason":                  self.reason,
            "location":                self.location,
            "secretary_comment":       self.secretary_comment,
            "updated_at":              self.updated_at.isoformat()      if self.updated_at      else None,
            # Joined names for convenience
            "patient_name": (
                f"{self.patient.user.first_name} {self.patient.user.last_name}"
                if self.patient and self.patient.user else None
            ),
            "doctor_name": (
                f"{self.doctor.user.first_name} {self.doctor.user.last_name}"
                if self.doctor and self.doctor.user else None
            ),
            "doctor_office_room": (
                self.doctor.office_room
                if self.doctor and self.doctor.office_room else None
            ),
        }

    def __repr__(self):
        return f"<Appointment {self.appointment_id} [{self.status}]>"
