"""
models/user.py — User ORM model.

Represents the base account for all roles: patient, doctor, secretary.
"""

from ..extensions import db


class User(db.Model):
    """Core user account shared by all roles."""

    __tablename__ = "user"

    user_id       = db.Column(db.Integer, primary_key=True, autoincrement=True)
    role          = db.Column(db.String(20), nullable=False)          # patient | doctor | secretary
    first_name    = db.Column(db.String(50), nullable=False)
    last_name     = db.Column(db.String(50), nullable=False)
    email         = db.Column(db.String(100), unique=True, nullable=False)
    phone         = db.Column(db.String(20))
    password_hash = db.Column(db.String(255), nullable=False)
    is_active     = db.Column(db.Boolean, default=True)
    created_at    = db.Column(db.DateTime, server_default=db.func.current_timestamp())
    updated_at    = db.Column(
        db.DateTime,
        server_default=db.func.current_timestamp(),
        onupdate=db.func.current_timestamp(),
    )

    # Relationships
    patient    = db.relationship("Patient",    back_populates="user", uselist=False)
    doctor     = db.relationship("Doctor",     back_populates="user", uselist=False)
    secretary  = db.relationship("Secretary",  back_populates="user", uselist=False)
    notifications = db.relationship("Notification", back_populates="user", lazy="dynamic")
    audit_logs    = db.relationship("AuditLog",     back_populates="actor", lazy="dynamic")

    def to_dict(self):
        """Return a safe dictionary representation (no password_hash)."""
        return {
            "user_id":    self.user_id,
            "role":       self.role,
            "first_name": self.first_name,
            "last_name":  self.last_name,
            "email":      self.email,
            "phone":      self.phone,
            "is_active":  self.is_active,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }

    def __repr__(self):
        return f"<User {self.user_id} {self.email} [{self.role}]>"
