"""
models/audit_log.py — AuditLog ORM model.
"""

from ..extensions import db


class AuditLog(db.Model):
    """Immutable record of every create/update/delete action in the system."""

    __tablename__ = "audit_log"

    audit_id      = db.Column(db.Integer, primary_key=True, autoincrement=True)
    actor_user_id = db.Column(db.Integer, db.ForeignKey("user.user_id"))
    action        = db.Column(db.String(100), nullable=False)
    entity_type   = db.Column(db.String(50))
    entity_id     = db.Column(db.Integer)
    ip_address    = db.Column(db.String(45))
    details       = db.Column(db.Text)
    created_at    = db.Column(db.DateTime, server_default=db.func.current_timestamp())

    # Relationships
    actor = db.relationship("User", back_populates="audit_logs")

    def to_dict(self):
        """Return a dictionary representation."""
        return {
            "audit_id":      self.audit_id,
            "actor_user_id": self.actor_user_id,
            "action":        self.action,
            "entity_type":   self.entity_type,
            "entity_id":     self.entity_id,
            "ip_address":    self.ip_address,
            "details":       self.details,
            "created_at":    self.created_at.isoformat() if self.created_at else None,
        }

    def __repr__(self):
        return f"<AuditLog {self.audit_id} actor={self.actor_user_id} action={self.action}>"
