"""
routes/patients.py — Patient CRUD and related data endpoints.

Secretary manages all patients; patients can read their own data.
"""

from flask import Blueprint, request, current_app
from flask_jwt_extended import get_jwt
from sqlalchemy import or_
from sqlalchemy.exc import SQLAlchemyError
from ..extensions import db
from ..models.patient import Patient
from ..models.user import User
from ..models.appointment import Appointment
from ..models.test_result import TestResult
from ..models.notification import Notification
from ..services.auth_service import hash_password
from ..services.test_validation_service import validate_and_flag
from ..utils.decorators import role_required, any_authenticated
from ..utils.responses import (
    success_response, error_response, created_response,
    not_found_response, forbidden_response
)
from ..utils.validators import validate_required_fields, validate_email, validate_password
from ..models.patient_medical_result import PatientMedicalResult
from ..models.chat_query_log import ChatQueryLog
from ..models.audit_log import AuditLog
from ..services.notification_service import send_notification

patients_bp = Blueprint("patients", __name__, url_prefix="/api/patients")


def _generate_patient_code():
    """Generate the next sequential patient code in PAT-XXX format."""
    max_code = db.session.query(
        db.func.max(Patient.patient_code)
    ).filter(
        Patient.patient_code.op("REGEXP")("^PAT-[0-9]{3}$")
    ).scalar()

    if max_code:
        num = int(max_code.split("-")[1]) + 1
    else:
        num = 1

    return f"PAT-{num:03d}"


def _log_action(actor_id, action, entity_id, details="", ip=None):
    """Helper to write an audit log entry."""
    log = AuditLog(
        actor_user_id=actor_id,
        action=action,
        entity_type="patient",
        entity_id=entity_id,
        ip_address=ip,
        details=details,
    )
    db.session.add(log)
    db.session.commit()


@patients_bp.route("/me", methods=["GET"])
@any_authenticated()
def get_my_profile():
    """Return the patient profile of the currently logged-in patient."""
    claims = get_jwt()
    user_id = claims.get("user_id")
    patient = Patient.query.filter_by(user_id=user_id).first()
    if not patient:
        return not_found_response("Patient profile not found")
    return success_response(data=patient.to_dict())


@patients_bp.route("", methods=["GET"])
@role_required("secretary")
def list_patients():
    """Return all patients. Secretary only."""
    patients = Patient.query.all()
    return success_response(data=[p.to_dict() for p in patients])


@patients_bp.route("/my-patients", methods=["GET"])
@role_required("doctor")
def list_doctor_patients():
    """Return patients who have appointments with the logged-in doctor. Doctor only."""
    from ..models.doctor import Doctor

    claims = get_jwt()
    user_id = claims.get("user_id")

    doctor = Doctor.query.filter_by(user_id=user_id).first()
    if not doctor:
        return success_response(data=[])

    patient_ids = db.session.query(Appointment.patient_id).filter(
        Appointment.doctor_id == doctor.doctor_id
    ).distinct().all()

    patient_ids = [p[0] for p in patient_ids]

    if not patient_ids:
        return success_response(data=[])

    patients = Patient.query.filter(Patient.patient_id.in_(patient_ids)).all()
    return success_response(data=[p.to_dict() for p in patients])


@patients_bp.route("", methods=["POST"])
@role_required("secretary")
def create_patient():
    """Create a new patient account. Secretary only."""
    data = request.get_json(silent=True) or {}
    claims = get_jwt()
    actor_id = claims.get("user_id")

    required = ["email", "password", "first_name", "last_name"]
    valid, err = validate_required_fields(data, required)
    if not valid:
        return error_response(err)

    valid, err = validate_email(data["email"])
    if not valid:
        return error_response(err)

    valid, err = validate_password(data["password"])
    if not valid:
        return error_response(err)

    if User.query.filter_by(email=data["email"].lower()).first():
        return error_response("Email already registered")

    user = User(
        role="patient",
        first_name=data["first_name"],
        last_name=data["last_name"],
        email=data["email"].strip().lower(),
        phone=data.get("phone"),
        password_hash=hash_password(data["password"]),
    )
    db.session.add(user)
    db.session.flush()  # get user_id before commit

    # Sanitize: convert empty string date fields to None to avoid DB type errors
    dob = data.get("date_of_birth")
    if dob == "" or dob is None:
        dob = None

    patient = Patient(
        user_id=user.user_id,
        patient_code=_generate_patient_code(),
        national_id=data.get("national_id"),
        date_of_birth=dob,
        gender=data.get("gender"),
        address=data.get("address"),
        blood_type=data.get("blood_type"),
        allergies=data.get("allergies"),
        chronic_conditions=data.get("chronic_conditions"),
        insurance_provider=data.get("insurance_provider"),
        insurance_number=data.get("insurance_number"),
        emergency_contact_name=data.get("emergency_contact_name"),
        emergency_contact_phone=data.get("emergency_contact_phone"),
    )
    db.session.add(patient)
    db.session.commit()

    _log_action(actor_id, "create_patient", patient.patient_id, f"Created patient {user.email}")
    send_notification(
        user_id=actor_id,
        title="Patient Created",
        message=f"You created a new patient: {user.first_name} {user.last_name} ({user.email}).",
        notif_type="info",
    )
    return created_response(data=patient.to_dict(), message="Patient created")


@patients_bp.route("/<int:patient_id>", methods=["GET"])
@any_authenticated()
def get_patient(patient_id):
    """Get a patient by ID. Doctor, Secretary, or the patient themselves."""
    claims = get_jwt()
    role = claims.get("role")
    user_id = claims.get("user_id")

    patient = Patient.query.get(patient_id)
    if not patient:
        return not_found_response("Patient not found")

    # Patient may only access their own record
    if role == "patient" and patient.user_id != user_id:
        return forbidden_response()

    return success_response(data=patient.to_dict())


@patients_bp.route("/<int:patient_id>", methods=["PUT"])
@role_required("secretary")
def update_patient(patient_id):
    """Update patient profile. Secretary only."""
    data = request.get_json(silent=True) or {}
    claims = get_jwt()
    actor_id = claims.get("user_id")

    patient = Patient.query.get(patient_id)
    if not patient:
        return not_found_response("Patient not found")

    # Update user fields
    user = patient.user
    for field in ["first_name", "last_name", "phone"]:
        if field in data:
            setattr(user, field, data[field])

    # Update patient-specific fields
    for field in [
        "patient_code", "national_id", "date_of_birth", "gender", "address",
        "blood_type", "allergies", "chronic_conditions", "insurance_provider",
        "insurance_number", "emergency_contact_name", "emergency_contact_phone"
    ]:
        if field in data:
            setattr(patient, field, data[field])

    db.session.commit()
    _log_action(actor_id, "update_patient", patient_id)
    return success_response(data=patient.to_dict(), message="Patient updated")


@patients_bp.route("/<int:patient_id>", methods=["DELETE"])
@role_required("secretary")
def delete_patient(patient_id):
    """Delete a patient and all linked records. Secretary only."""
    claims = get_jwt()
    actor_id = claims.get("user_id")

    patient = Patient.query.get(patient_id)
    if not patient:
        return not_found_response("Patient not found")

    user = patient.user
    user_id = user.user_id
    patient_name = f"{user.first_name} {user.last_name}"
    patient_email = user.email

    try:
        from ..models.body_health import BodyHealth
        BodyHealth.query.filter_by(patient_id=patient_id).delete()

        PatientMedicalResult.query.filter(
            or_(
                PatientMedicalResult.patient_id == patient_id,
                PatientMedicalResult.created_by_user_id == user_id
            )
        ).delete(synchronize_session=False)

        Appointment.query.filter_by(patient_id=patient_id).delete()

        TestResult.query.filter_by(patient_id=patient_id).delete()

        Notification.query.filter_by(user_id=user_id).delete()

        from ..models.patient_doctor_assignment import PatientDoctorAssignment
        PatientDoctorAssignment.query.filter_by(patient_id=patient_id).delete()

        ChatQueryLog.query.filter_by(user_id=user_id).delete()

        AuditLog.query.filter_by(actor_user_id=user_id).delete()

        db.session.delete(patient)
        db.session.delete(user)

        log = AuditLog(
            actor_user_id=actor_id,
            action="delete_patient",
            entity_type="patient",
            entity_id=patient_id,
            details=f"Deleted patient: {patient_name} ({patient_email})",
        )
        db.session.add(log)
        db.session.commit()

    except SQLAlchemyError as e:
        db.session.rollback()
        current_app.logger.error(f"Failed to delete patient {patient_id}: {e}")
        return error_response("Failed to delete patient. Please try again.")

    send_notification(
        user_id=actor_id,
        title="Patient Deleted",
        message=f"You deleted patient: {patient_name} ({patient_email}).",
        notif_type="info",
    )
    return success_response(message="Patient deleted")


@patients_bp.route("/<int:patient_id>/appointments", methods=["GET"])
@any_authenticated()
def get_patient_appointments(patient_id):
    """List appointments for a patient. Scoped by role."""
    claims = get_jwt()
    role = claims.get("role")
    user_id = claims.get("user_id")

    patient = Patient.query.get(patient_id)
    if not patient:
        return not_found_response("Patient not found")

    if role == "patient" and patient.user_id != user_id:
        return forbidden_response()

    appts = Appointment.query.filter_by(patient_id=patient_id).order_by(
        Appointment.scheduled_start.desc()
    ).all()
    return success_response(data=[a.to_dict() for a in appts])


@patients_bp.route("/<int:patient_id>/test-results", methods=["GET"])
@any_authenticated()
def get_patient_test_results(patient_id):
    """List test results for a patient."""
    claims = get_jwt()
    role = claims.get("role")
    user_id = claims.get("user_id")

    patient = Patient.query.get(patient_id)
    if not patient:
        return not_found_response("Patient not found")

    if role == "patient" and patient.user_id != user_id:
        return forbidden_response()

    results = TestResult.query.filter_by(patient_id=patient_id).order_by(
        TestResult.result_date.desc()
    ).all()
    return success_response(data=[r.to_dict() for r in results])


@patients_bp.route("/<int:patient_id>/medical-history", methods=["GET"])
@any_authenticated()
def get_medical_history(patient_id):
    """Return combined medical history (appointments + results)."""
    claims = get_jwt()
    role = claims.get("role")
    user_id = claims.get("user_id")

    patient = Patient.query.get(patient_id)
    if not patient:
        return not_found_response("Patient not found")

    if role == "patient" and patient.user_id != user_id:
        return forbidden_response()

    appts   = Appointment.query.filter_by(patient_id=patient_id).all()
    results = TestResult.query.filter_by(patient_id=patient_id).all()

    return success_response(data={
        "patient":      patient.to_dict(),
        "appointments": [a.to_dict() for a in appts],
        "test_results": [r.to_dict() for r in results],
    })


@patients_bp.route("/<int:patient_id>/home-tests", methods=["POST"])
@role_required("patient")
def submit_home_test(patient_id):
    """Patient submits a home measurement."""
    data = request.get_json(silent=True) or {}
    claims = get_jwt()
    user_id = claims.get("user_id")

    patient = Patient.query.get(patient_id)
    if not patient:
        return not_found_response("Patient not found")

    if patient.user_id != user_id:
        return forbidden_response()

    required = ["test_id", "doctor_id", "value", "result_date"]
    valid, err = validate_required_fields(data, required)
    if not valid:
        return error_response(err)

    from datetime import datetime
    result = TestResult(
        patient_id=patient_id,
        doctor_id=data["doctor_id"],
        test_id=data["test_id"],
        value=data["value"],
        unit=data.get("unit"),
        result_date=datetime.fromisoformat(data["result_date"]),
        fasting_state=data.get("fasting_state"),
        notes=data.get("notes"),
        validation_method="home_submission",
    )
    db.session.add(result)
    db.session.commit()

    validate_and_flag(result)
    return created_response(data=result.to_dict(), message="Home test submitted")
