"""
routes/doctors.py — Doctor CRUD endpoints.

Secretary manages doctors; doctors can read their own data.
"""

from flask import Blueprint, request
from flask_jwt_extended import get_jwt
from ..extensions import db
from ..models.doctor import Doctor
from ..models.user import User
from ..models.appointment import Appointment
from ..models.patient_doctor_assignment import PatientDoctorAssignment
from ..services.auth_service import hash_password
from ..utils.decorators import role_required, any_authenticated
from ..utils.responses import (
    success_response, error_response, created_response,
    not_found_response, forbidden_response
)
from ..utils.validators import validate_required_fields, validate_email, validate_password
from ..models.audit_log import AuditLog
from ..services.notification_service import send_notification

doctors_bp = Blueprint("doctors", __name__, url_prefix="/api/doctors")


def _log(actor_id, action, entity_id, details=""):
    log = AuditLog(actor_user_id=actor_id, action=action, entity_type="doctor", entity_id=entity_id, details=details)
    db.session.add(log)
    db.session.commit()


@doctors_bp.route("", methods=["GET"])
@any_authenticated()
def list_doctors():
    """List all doctors. Secretary only."""
    doctors = Doctor.query.all()
    return success_response(data=[d.to_dict() for d in doctors])


@doctors_bp.route("/available", methods=["GET"])
@any_authenticated()
def list_available_doctors():
    """List all active doctors. Any authenticated user (for booking)."""
    doctors = Doctor.query.filter(Doctor.user.has(is_active=True)).all()
    return success_response(data=[d.to_dict() for d in doctors])


@doctors_bp.route("", methods=["POST"])
@role_required("secretary")
def create_doctor():
    """Create a new doctor account. Secretary only."""
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
        role="doctor",
        first_name=data["first_name"],
        last_name=data["last_name"],
        email=data["email"].strip().lower(),
        phone=data.get("phone"),
        password_hash=hash_password(data["password"]),
    )
    db.session.add(user)
    db.session.flush()

    doctor = Doctor(
        user_id=user.user_id,
        specialization=data.get("specialization"),
        license_number=data.get("license_number"),
        office_room=data.get("office_room"),
    )
    db.session.add(doctor)
    db.session.commit()

    _log(actor_id, "create_doctor", doctor.doctor_id, f"Created doctor {user.email}")
    send_notification(
        user_id=actor_id,
        title="Doctor Created",
        message=f"You created a new doctor: Dr. {user.first_name} {user.last_name} ({user.email}).",
        notif_type="info",
    )
    return created_response(data=doctor.to_dict(), message="Doctor created")


@doctors_bp.route("/<int:doctor_id>", methods=["GET"])
@any_authenticated()
def get_doctor(doctor_id):
    """Get a doctor by ID."""
    doctor = Doctor.query.get(doctor_id)
    if not doctor:
        return not_found_response("Doctor not found")
    return success_response(data=doctor.to_dict())


@doctors_bp.route("/<int:doctor_id>", methods=["PUT"])
@role_required("secretary")
def update_doctor(doctor_id):
    """Update doctor info. Secretary only."""
    data = request.get_json(silent=True) or {}
    claims = get_jwt()
    actor_id = claims.get("user_id")

    doctor = Doctor.query.get(doctor_id)
    if not doctor:
        return not_found_response("Doctor not found")

    user = doctor.user
    for field in ["first_name", "last_name", "phone"]:
        if field in data:
            setattr(user, field, data[field])
    for field in ["specialization", "license_number", "office_room"]:
        if field in data:
            setattr(doctor, field, data[field])

    db.session.commit()
    _log(actor_id, "update_doctor", doctor_id)
    return success_response(data=doctor.to_dict(), message="Doctor updated")


@doctors_bp.route("/<int:doctor_id>", methods=["DELETE"])
@role_required("secretary")
def delete_doctor(doctor_id):
    """Delete a doctor and their user account. Secretary only."""
    claims = get_jwt()
    actor_id = claims.get("user_id")

    doctor = Doctor.query.get(doctor_id)
    if not doctor:
        return not_found_response("Doctor not found")

    user = doctor.user
    doctor_id_val = doctor.doctor_id

    # Delete all related records first
    # Appointments
    Appointment.query.filter_by(doctor_id=doctor_id_val).delete()
    # Test results (where doctor_id is set)
    from ..models.test_result import TestResult
    TestResult.query.filter_by(doctor_id=doctor_id_val).delete()
    # Patient-Doctor assignments
    from ..models.patient_doctor_assignment import PatientDoctorAssignment
    PatientDoctorAssignment.query.filter_by(doctor_id=doctor_id_val).delete()

    # Delete doctor first (to avoid FK constraint issues)
    db.session.delete(doctor)
    # Then delete user
    db.session.delete(user)
    db.session.commit()

    _log(actor_id, "delete_doctor", doctor_id_val)
    send_notification(
        user_id=actor_id,
        title="Doctor Deleted",
        message=f"You deleted doctor: Dr. {user.first_name} {user.last_name} ({user.email}).",
        notif_type="info",
    )
    return success_response(message="Doctor deleted")


@doctors_bp.route("/<int:doctor_id>/appointments", methods=["GET"])
@any_authenticated()
def get_doctor_appointments(doctor_id):
    """List appointments for a doctor."""
    claims = get_jwt()
    role = claims.get("role")
    user_id = claims.get("user_id")

    doctor = Doctor.query.get(doctor_id)
    if not doctor:
        return not_found_response("Doctor not found")

    # Doctor may only view their own appointments
    if role == "doctor" and doctor.user_id != user_id:
        return forbidden_response()

    appts = Appointment.query.filter_by(doctor_id=doctor_id).order_by(
        Appointment.scheduled_start.desc()
    ).all()
    return success_response(data=[a.to_dict() for a in appts])


@doctors_bp.route("/<int:doctor_id>/patients", methods=["GET"])
@any_authenticated()
def get_doctor_patients(doctor_id):
    """List patients assigned to a doctor."""
    claims = get_jwt()
    role = claims.get("role")
    user_id = claims.get("user_id")

    doctor = Doctor.query.get(doctor_id)
    if not doctor:
        return not_found_response("Doctor not found")

    if role == "doctor" and doctor.user_id != user_id:
        return forbidden_response()

    assignments = PatientDoctorAssignment.query.filter_by(
        doctor_id=doctor_id, is_active=True
    ).all()
    patients = [a.patient.to_dict() for a in assignments if a.patient]
    return success_response(data=patients)
