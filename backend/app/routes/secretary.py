"""
routes/secretary.py — Secretary account management.

Secretaries can create / view their own profile.
Admin creation of secretary accounts is also handled here.
"""

from datetime import date

from flask import Blueprint, request
from flask_jwt_extended import get_jwt
from ..extensions import db
from ..models.secretary import Secretary
from ..models.user import User
from ..models.appointment import Appointment
from ..models.doctor import Doctor
from ..services.auth_service import hash_password
from ..utils.decorators import role_required, any_authenticated
from ..utils.responses import (
    success_response, error_response, created_response, not_found_response
)
from ..utils.validators import validate_required_fields, validate_email
from ..models.audit_log import AuditLog

secretary_bp = Blueprint("secretary", __name__, url_prefix="/api/secretaries")


def _log(actor_id, action, entity_id, details=""):
    log = AuditLog(actor_user_id=actor_id, action=action, entity_type="secretary", entity_id=entity_id, details=details)
    db.session.add(log)
    db.session.commit()


@secretary_bp.route("", methods=["GET"])
@role_required("secretary")
def list_secretaries():
    """List all secretaries. Secretary only."""
    secretaries = Secretary.query.all()
    return success_response(data=[s.to_dict() for s in secretaries])


@secretary_bp.route("", methods=["POST"])
@role_required("secretary")
def create_secretary():
    """Create a new secretary account. Secretary only."""
    data = request.get_json(silent=True) or {}
    claims = get_jwt()
    actor_id = claims.get("user_id")

    valid, err = validate_required_fields(data, ["email", "password", "first_name", "last_name"])
    if not valid:
        return error_response(err)

    valid, err = validate_email(data["email"])
    if not valid:
        return error_response(err)

    if User.query.filter_by(email=data["email"].lower()).first():
        return error_response("Email already registered")

    user = User(
        role="secretary",
        first_name=data["first_name"],
        last_name=data["last_name"],
        email=data["email"].strip().lower(),
        phone=data.get("phone"),
        password_hash=hash_password(data["password"]),
    )
    db.session.add(user)
    db.session.flush()

    sec = Secretary(
        user_id=user.user_id,
        employee_code=data.get("employee_code"),
    )
    db.session.add(sec)
    db.session.commit()

    _log(actor_id, "create_secretary", sec.secretary_id)
    return created_response(data=sec.to_dict(), message="Secretary created")


@secretary_bp.route("/<int:secretary_id>", methods=["GET"])
@any_authenticated()
def get_secretary(secretary_id):
    """Get secretary by ID."""
    sec = Secretary.query.get(secretary_id)
    if not sec:
        return not_found_response("Secretary not found")
    return success_response(data=sec.to_dict())


@secretary_bp.route("/dashboard-summary", methods=["GET"])
@role_required("secretary")
def dashboard_summary():
    """Return today's schedule + doctor workload for the secretary dashboard."""
    today = date.today()

    total_patients = User.query.filter(User.role == "patient").count()
    total_doctors  = User.query.filter(User.role == "doctor").count()

    today_appts = Appointment.query.filter(
        db.func.date(Appointment.scheduled_start) == today
    ).order_by(Appointment.scheduled_start.asc()).all()

    today_schedule = []
    for a in today_appts:
        patient_name = (
            f"{a.patient.user.first_name} {a.patient.user.last_name}"
            if a.patient and a.patient.user else "Unknown"
        )
        doctor_name = (
            f"Dr. {a.doctor.user.first_name} {a.doctor.user.last_name}"
            if a.doctor and a.doctor.user else "Unknown"
        )
        today_schedule.append({
            "appointment_id": a.appointment_id,
            "time":           a.scheduled_start.strftime("%H:%M") if a.scheduled_start else "",
            "patient_name":   patient_name,
            "doctor_name":    doctor_name,
            "reason":         a.reason or "—",
            "status":         a.status,
        })

    today_appointments_count = len(today_appts)

    doctors = Doctor.query.all()
    doctor_workload = []
    for d in doctors:
        count = Appointment.query.filter(
            Appointment.doctor_id == d.doctor_id,
            db.func.date(Appointment.scheduled_start) == today,
        ).count()

        if count == 0:
            label = "Free"
        elif count <= 4:
            label = "Available"
        elif count <= 7:
            label = "Moderate"
        else:
            label = "Busy"

        doctor_name = (
            f"Dr. {d.user.first_name} {d.user.last_name}" if d.user else "Unknown"
        )

        doctor_workload.append({
            "doctor_id":         d.doctor_id,
            "name":              doctor_name,
            "specialization":    d.specialization or "—",
            "appointments_today": count,
            "status_label":      label,
        })

    return success_response(data={
        "total_patients":         total_patients,
        "total_doctors":          total_doctors,
        "today_appointments_count": today_appointments_count,
        "today_schedule":          today_schedule,
        "doctor_workload":         doctor_workload,
    })
