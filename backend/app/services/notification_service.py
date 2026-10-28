"""
services/notification_service.py — Create and retrieve notifications.
"""

from ..extensions import db
from ..models.notification import Notification


def send_notification(user_id: int, title: str, message: str, notif_type: str = "info"):
    """
    Create and persist an in-app notification for a user.

    Args:
        user_id:     The recipient user's ID.
        title:       Short notification title.
        message:     Full notification body.
        notif_type:  Category string (e.g. 'appointment', 'test_result', 'info').

    Returns:
        The saved Notification ORM object.
    """
    notif = Notification(
        user_id=user_id,
        type=notif_type,
        title=title,
        message=message,
    )
    db.session.add(notif)
    db.session.commit()
    return notif


def mark_as_read(notification_id: int, user_id: int):
    """
    Mark a notification as read.
    Returns the notification or None if not found / not owned by user.
    """
    from datetime import datetime
    notif = Notification.query.filter_by(
        notification_id=notification_id,
        user_id=user_id,
    ).first()
    if notif:
        notif.is_read = True
        notif.read_at = datetime.utcnow()
        db.session.commit()
    return notif


def delete_notification(notification_id: int, user_id: int):
    """
    Delete a notification owned by the given user.
    Returns True if deleted, False if not found.
    """
    notif = Notification.query.filter_by(
        notification_id=notification_id,
        user_id=user_id,
    ).first()
    if notif:
        db.session.delete(notif)
        db.session.commit()
        return True
    return False


def get_user_notifications(user_id: int):
    """Return all notifications for a user, newest first."""
    return (
        Notification.query
        .filter_by(user_id=user_id)
        .order_by(Notification.created_at.desc())
        .all()
    )
