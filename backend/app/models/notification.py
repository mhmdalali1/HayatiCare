"""
models/notification.py — Notification ORM model.
"""

from ..extensions import db


class Notification(db.Model):
    """In-app notification sent to a user."""

    __tablename__ = "notification"

    notification_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id         = db.Column(db.Integer, db.ForeignKey("user.user_id", ondelete="CASCADE"), nullable=False)
    type            = db.Column(db.String(50))
    title           = db.Column(db.String(150))
    message         = db.Column(db.Text)
    is_read         = db.Column(db.Boolean, default=False)
    created_at      = db.Column(db.DateTime, server_default=db.func.current_timestamp())
    read_at         = db.Column(db.DateTime)

    # Relationships
    user = db.relationship("User", back_populates="notifications")

    def to_dict(self):
        """Return a dictionary representation."""
        return {
            "notification_id": self.notification_id,
            "user_id":         self.user_id,
            "type":            self.type,
            "title":           self.title,
            "message":         self.message,
            "is_read":         self.is_read,
            "created_at":      self.created_at.isoformat() if self.created_at else None,
            "read_at":         self.read_at.isoformat()    if self.read_at    else None,
        }

    def __repr__(self):
        return f"<Notification {self.notification_id} user={self.user_id} read={self.is_read}>"
