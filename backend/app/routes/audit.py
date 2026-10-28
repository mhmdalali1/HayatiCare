"""
routes/audit.py — Audit log retrieval endpoint.

GET /api/audit  — Secretary only
"""

from flask import Blueprint, request
from ..extensions import db
from ..models.audit_log import AuditLog
from ..utils.decorators import role_required
from ..utils.responses import success_response

audit_bp = Blueprint("audit", __name__, url_prefix="/api/audit")


@audit_bp.route("", methods=["GET"])
@role_required("secretary")
def list_audit_logs():
    """
    Return audit log entries. Secretary only.
    Supports optional query params:
      - entity_type  (e.g. "patient", "appointment")
      - actor_user_id
      - limit        (default 200)
      - offset       (default 0)
    """
    entity_type   = request.args.get("entity_type")
    actor_user_id = request.args.get("actor_user_id", type=int)
    limit         = request.args.get("limit", default=200, type=int)
    offset        = request.args.get("offset", default=0, type=int)

    query = AuditLog.query

    if entity_type:
        query = query.filter_by(entity_type=entity_type)
    if actor_user_id:
        query = query.filter_by(actor_user_id=actor_user_id)

    logs = (
        query.order_by(AuditLog.created_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )
    total = query.count()

    return success_response(data={
        "logs":   [log.to_dict() for log in logs],
        "total":  total,
        "limit":  limit,
        "offset": offset,
    })
