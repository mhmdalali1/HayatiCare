"""
routes/test_results.py — Test result upload and retrieval.

GET    /api/test-results           — filtered by role
POST   /api/test-results           — Doctor or Secretary uploads
GET    /api/test-results/<id>
GET    /api/test-results/flagged   — Doctor sees flagged results for own patients
"""

from datetime import datetime
from flask import Blueprint, request
from flask_jwt_extended import get_jwt
from ..extensions import db
from ..models.test_result import TestResult
from ..models.patient import Patient
from ..models.doctor import Doctor
from ..models.secretary import Secretary
from ..models.patient_doctor_assignment import PatientDoctorAssignment
from ..services.test_validation_service import validate_and_flag
from ..utils.decorators import role_required, any_authenticated
from ..utils.responses import (
    success_response, error_response, created_response,
    not_found_response, forbidden_response
)
from ..utils.validators import validate_required_fields
from ..models.audit_log import AuditLog

test_results_bp = Blueprint("test_results", __name__, url_prefix="/api/test-results")


def _log(actor_id, action, entity_id, details=""):
    log = AuditLog(actor_user_id=actor_id, action=action, entity_type="test_result", entity_id=entity_id, details=details)
    db.session.add(log)
    db.session.commit()


@test_results_bp.route("", methods=["GET"])
@any_authenticated()
def list_results():
    """
    List test results filtered by role:
      - Secretary / Doctor: all results (or own-doctor filtered)
      - Patient: own results only
    """
    claims  = get_jwt()
    role    = claims.get("role")
    user_id = claims.get("user_id")

    query = TestResult.query

    if role == "patient":
        patient = Patient.query.filter_by(user_id=user_id).first()
        if not patient:
            return error_response("Patient profile not found")
        query = query.filter_by(patient_id=patient.patient_id)
    elif role == "doctor":
        doctor = Doctor.query.filter_by(user_id=user_id).first()
        if not doctor:
            return error_response("Doctor profile not found")
        query = query.filter_by(doctor_id=doctor.doctor_id)

    results = query.order_by(TestResult.result_date.desc()).all()
    return success_response(data=[r.to_dict() for r in results])


@test_results_bp.route("", methods=["POST"])
@role_required("doctor", "secretary")
def upload_result():
    """Upload a new test result. Doctor or Secretary."""
    data    = request.get_json(silent=True) or {}
    claims  = get_jwt()
    role    = claims.get("role")
    user_id = claims.get("user_id")

    valid, err = validate_required_fields(data, ["patient_id", "doctor_id", "test_id", "value"])
    if not valid:
        return error_response(err)

    secretary_id = None
    if role == "secretary":
        sec = Secretary.query.filter_by(user_id=user_id).first()
        if sec:
            secretary_id = sec.secretary_id

    result_date = data.get("result_date")
    if result_date:
        try:
            result_date = datetime.fromisoformat(result_date)
        except ValueError:
            return error_response("Invalid result_date format")
    else:
        result_date = datetime.utcnow()

    result = TestResult(
        patient_id=int(data["patient_id"]),
        doctor_id=int(data["doctor_id"]),
        test_id=int(data["test_id"]),
        secretary_id=secretary_id,
        value=data["value"],
        unit=data.get("unit"),
        result_date=result_date,
        fasting_state=data.get("fasting_state"),
        notes=data.get("notes"),
    )
    db.session.add(result)
    db.session.commit()

    # Auto-flag logic
    validate_and_flag(result)

    _log(user_id, "upload_test_result", result.result_id)
    return created_response(data=result.to_dict(), message="Test result uploaded")


@test_results_bp.route("/flagged", methods=["GET"])
@role_required("doctor", "secretary")
def list_flagged():
    """
    Return flagged (abnormal) test results.
    Doctor sees only their own patients' results; Secretary sees all.
    """
    claims  = get_jwt()
    role    = claims.get("role")
    user_id = claims.get("user_id")

    query = TestResult.query.filter_by(is_flagged=True)

    if role == "doctor":
        doctor = Doctor.query.filter_by(user_id=user_id).first()
        if not doctor:
            return error_response("Doctor profile not found")
        query = query.filter_by(doctor_id=doctor.doctor_id)

    results = query.order_by(TestResult.result_date.desc()).all()
    return success_response(data=[r.to_dict() for r in results])


@test_results_bp.route("/<int:result_id>", methods=["GET"])
@any_authenticated()
def get_result(result_id):
    """Get a single test result. Scoped by role."""
    claims  = get_jwt()
    role    = claims.get("role")
    user_id = claims.get("user_id")

    result = TestResult.query.get(result_id)
    if not result:
        return not_found_response("Test result not found")

    if role == "patient":
        patient = Patient.query.filter_by(user_id=user_id).first()
        if not patient or result.patient_id != patient.patient_id:
            return forbidden_response()
    elif role == "doctor":
        doctor = Doctor.query.filter_by(user_id=user_id).first()
        if not doctor or result.doctor_id != doctor.doctor_id:
            return forbidden_response()

    return success_response(data=result.to_dict())
