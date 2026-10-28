"""
routes/notifications.py — Notification send and view endpoints.

GET    /api/notifications              — own notifications
POST   /api/notifications             — Doctor or Secretary sends
PUT    /api/notifications/<id>/read
DELETE /api/notifications/<id>
"""

from flask import Blueprint, request
from flask_jwt_extended import get_jwt
from ..services.notification_service import (
    get_user_notifications, send_notification,
    mark_as_read, delete_notification
)
from ..utils.decorators import role_required, any_authenticated
from ..utils.responses import (
    success_response, error_response, created_response, not_found_response
)
from ..utils.validators import validate_required_fields

notifications_bp = Blueprint("notifications", __name__, url_prefix="/api/notifications")


@notifications_bp.route("", methods=["GET"])
@any_authenticated()
def list_notifications():
    """Return all notifications for the authenticated user."""
    claims  = get_jwt()
    user_id = claims.get("user_id")
    notifs  = get_user_notifications(user_id)
    return success_response(data=[n.to_dict() for n in notifs])


@notifications_bp.route("", methods=["POST"])
@role_required("doctor", "secretary")
def create_notification():
    """Send a notification to a user. Doctor or Secretary only."""
    data    = request.get_json(silent=True) or {}
    claims  = get_jwt()

    valid, err = validate_required_fields(data, ["user_id", "title", "message"])
    if not valid:
        return error_response(err)

    notif = send_notification(
        user_id=int(data["user_id"]),
        title=data["title"],
        message=data["message"],
        notif_type=data.get("type", "info"),
    )
    return created_response(data=notif.to_dict(), message="Notification sent")


@notifications_bp.route("/<int:notification_id>/read", methods=["PUT"])
@any_authenticated()
def mark_notification_read(notification_id):
    """Mark a notification as read."""
    claims  = get_jwt()
    user_id = claims.get("user_id")

    notif = mark_as_read(notification_id, user_id)
    if not notif:
        return not_found_response("Notification not found")
    return success_response(data=notif.to_dict(), message="Marked as read")


@notifications_bp.route("/<int:notification_id>", methods=["DELETE"])
@any_authenticated()
def remove_notification(notification_id):
    """Delete a notification owned by the current user."""
    claims  = get_jwt()
    user_id = claims.get("user_id")

    deleted = delete_notification(notification_id, user_id)
    if not deleted:
        return not_found_response("Notification not found")
    return success_response(message="Notification deleted")
