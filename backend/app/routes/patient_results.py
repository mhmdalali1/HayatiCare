import time
from sqlalchemy import func
from flask import Blueprint, request
from flask_jwt_extended import get_jwt
from ..extensions import db
from ..models.patient_medical_result import PatientMedicalResult
from ..models.patient import Patient
from ..models.doctor import Doctor
from ..models.patient_doctor_assignment import PatientDoctorAssignment
from ..utils.decorators import role_required, any_authenticated
from ..utils.responses import (
    success_response, error_response, created_response,
    not_found_response, forbidden_response
)
from ..utils.validators import validate_required_fields

patient_results_bp = Blueprint("patient_results", __name__, url_prefix="/api/patient-results")

NORMAL_RANGES = {
    "GLU":  (3.9, 5.5),
    "HGB":  (12.0, 17.5),
    "CHOL": (0.0, 5.2),
    "WBC":  (4.0, 11.0),
    "PLT":  (150, 450),
    "NA":   (135, 145),
    "K":    (3.5, 5.0),
    "CRE":  (0.6, 1.3),
    "ALT":  (7, 56),
    "AST":  (10, 40),
    "SPO2": (95, 100),
    "TEMP": (36.1, 37.2),
}


def _auto_status(test_code: str, value_str: str) -> str:
    if not value_str:
        return "normal"
    test_code = test_code.upper()
    if test_code == "BP":
        return "normal"
    try:
        val = float(value_str)
    except (ValueError, TypeError):
        return "normal"
    r = NORMAL_RANGES.get(test_code)
    if r is None:
        return "normal"
    lo, hi = r
    if val < lo:
        return "low"
    if val > hi:
        return "high"
    return "normal"


@patient_results_bp.route("", methods=["GET"])
@any_authenticated()
def list_results():
    claims = get_jwt()
    role = claims.get("role")
    user_id = claims.get("user_id")

    query = PatientMedicalResult.query

    if role == "patient":
        patient = Patient.query.filter_by(user_id=user_id).first()
        if not patient:
            return error_response("Patient profile not found")
        query = query.filter_by(patient_id=patient.patient_id)
    elif role == "doctor":
        doctor = Doctor.query.filter_by(user_id=user_id).first()
        if not doctor:
            return error_response("Doctor profile not found")
        patient_ids = [
            a.patient_id
            for a in PatientDoctorAssignment.query.filter_by(
                doctor_id=doctor.doctor_id, is_active=True
            ).all()
        ]
        if patient_ids:
            query = query.filter(PatientMedicalResult.patient_id.in_(patient_ids))

    results = query.order_by(PatientMedicalResult.created_at.desc()).all()
    return success_response(data=[r.to_dict() for r in results])


@patient_results_bp.route("", methods=["POST"])
@role_required("secretary")
def create_result():
    data = request.get_json(silent=True) or {}
    claims = get_jwt()
    user_id = claims.get("user_id")

    valid, err = validate_required_fields(data, ["patient_id", "test_id", "value"])
    if not valid:
        return error_response(err)

    patient = Patient.query.get(int(data["patient_id"]))
    if not patient:
        return error_response("Patient not found")

    from ..models.medical_test import MedicalTest
    test = MedicalTest.query.get(int(data["test_id"]))
    if not test:
        return error_response("Medical test not found")

    value_str = str(data["value"]).strip()
    unit = data.get("unit") or test.default_unit or ""
    status = _auto_status(test.test_code, value_str)

    batch_id = int(time.time() * 1000)

    result = PatientMedicalResult(
        patient_id=patient.patient_id,
        test_id=test.test_id,
        value=value_str,
        unit=unit,
        status=status,
        created_by_user_id=user_id,
        batch_id=batch_id,
    )
    db.session.add(result)
    db.session.commit()

    # Notify patient
    if patient and patient.user:
        from ..services.notification_service import send_notification
        send_notification(
            user_id=patient.user_id,
            title="New Test Results Available",
            message="Your doctor has uploaded new test results. Tap to view.",
            notif_type="test_result",
        )

    return created_response(data=result.to_dict(), message="Result submitted")


@patient_results_bp.route("/batch", methods=["POST"])
@role_required("secretary")
def create_batch_results():
    data = request.get_json(silent=True) or {}
    claims = get_jwt()
    user_id = claims.get("user_id")

    results_data = data.get("results", [])
    if not results_data:
        return error_response("No results provided")

    from ..models.medical_test import MedicalTest

    batch_id = int(time.time() * 1000)
    created = []

    for item in results_data:
        valid, err = validate_required_fields(item, ["patient_id", "test_id", "value"])
        if not valid:
            continue

        patient = Patient.query.get(int(item["patient_id"]))
        if not patient:
            continue

        test = MedicalTest.query.get(int(item["test_id"]))
        if not test:
            continue

        value_str = str(item["value"]).strip()
        unit = item.get("unit") or test.default_unit or ""
        status = _auto_status(test.test_code, value_str)

        result = PatientMedicalResult(
            patient_id=patient.patient_id,
            test_id=test.test_id,
            value=value_str,
            unit=unit,
            status=status,
            created_by_user_id=user_id,
            batch_id=batch_id,
        )
        db.session.add(result)
        created.append(result)

    db.session.commit()

    # Send notification to each patient whose results were actually created
    notified_patients = set()
    for r in created:
        if r.patient_id not in notified_patients:
            notified_patients.add(r.patient_id)
            patient = Patient.query.get(r.patient_id)
            if patient and patient.user:
                from ..services.notification_service import send_notification
                send_notification(
                    user_id=patient.user_id,
                    title="New Test Results Available",
                    message="Your doctor has uploaded new test results. Tap to view.",
                    notif_type="test_result",
                )

    return created_response(
        data={"batch_id": batch_id, "count": len(created), "results": [r.to_dict() for r in created]},
        message=f"{len(created)} results submitted"
    )


@patient_results_bp.route("/patient/<int:patient_id>/batches", methods=["GET"])
@any_authenticated()
def patient_batches(patient_id):
    claims = get_jwt()
    role = claims.get("role")
    user_id = claims.get("user_id")

    if role == "patient":
        patient = Patient.query.filter_by(user_id=user_id).first()
        if not patient or patient.patient_id != patient_id:
            return forbidden_response()

    patient_obj = Patient.query.get(patient_id)
    base_name = f"{patient_obj.user.first_name} {patient_obj.user.last_name}" if patient_obj and patient_obj.user else ""
    base_code = patient_obj.patient_code if patient_obj else ""

    rows_with_batch = db.session.query(
        PatientMedicalResult.batch_id,
        func.min(PatientMedicalResult.created_at).label("batch_date"),
        func.count(PatientMedicalResult.result_id).label("count")
    ).filter(
        PatientMedicalResult.patient_id == patient_id,
        PatientMedicalResult.batch_id.isnot(None)
    ).group_by(PatientMedicalResult.batch_id).order_by(
        func.min(PatientMedicalResult.created_at).desc()
    ).all()

    rows_no_batch = db.session.query(
        PatientMedicalResult.created_at,
        func.count(PatientMedicalResult.result_id).label("count")
    ).filter(
        PatientMedicalResult.patient_id == patient_id,
        PatientMedicalResult.batch_id.is_(None)
    ).group_by(PatientMedicalResult.created_at).order_by(
        PatientMedicalResult.created_at.desc()
    ).all()

    data = []
    for r in rows_with_batch:
        data.append({
            "batch_id": r.batch_id,
            "batch_date": r.batch_date.isoformat() if r.batch_date else None,
            "result_count": r.count,
            "patient_name": base_name,
            "patient_code": base_code,
        })
    for r in rows_no_batch:
        ts = int(r.created_at.timestamp() * 1000) if r.created_at else 0
        data.append({
            "batch_id": -ts,
            "batch_date": r.created_at.isoformat() if r.created_at else None,
            "result_count": r.count,
            "patient_name": base_name,
            "patient_code": base_code,
        })

    return success_response(data=data)


@patient_results_bp.route("/batch/<batch_id>", methods=["GET"])
@any_authenticated()
def batch_results(batch_id):
    try:
        batch_id = int(batch_id)
    except (ValueError, TypeError):
        return error_response("Invalid batch_id")

    claims = get_jwt()
    role = claims.get("role")
    user_id = claims.get("user_id")

    if batch_id < 0:
        ts_ms = -batch_id
        from datetime import datetime
        dt = datetime.fromtimestamp(ts_ms / 1000.0)
        query = PatientMedicalResult.query.filter(
            PatientMedicalResult.batch_id.is_(None),
            PatientMedicalResult.created_at == dt
        )
    else:
        query = PatientMedicalResult.query.filter_by(batch_id=batch_id)

    if role == "patient":
        patient = Patient.query.filter_by(user_id=user_id).first()
        if not patient:
            return error_response("Patient profile not found")
        query = query.filter(PatientMedicalResult.patient_id == patient.patient_id)
    elif role == "doctor":
        doctor = Doctor.query.filter_by(user_id=user_id).first()
        if not doctor:
            return error_response("Doctor profile not found")
        patient_ids = [
            a.patient_id
            for a in PatientDoctorAssignment.query.filter_by(
                doctor_id=doctor.doctor_id, is_active=True
            ).all()
        ]
        if patient_ids:
            query = query.filter(PatientMedicalResult.patient_id.in_(patient_ids))

    results = query.order_by(PatientMedicalResult.created_at.asc()).all()
    return success_response(data=[r.to_dict() for r in results])


@patient_results_bp.route("/grouped-by-patient", methods=["GET"])
@any_authenticated()
def grouped_by_patient():
    claims = get_jwt()
    role = claims.get("role")
    user_id = claims.get("user_id")

    query = db.session.query(
        PatientMedicalResult.patient_id,
        func.count(PatientMedicalResult.result_id).label("count"),
        func.max(PatientMedicalResult.created_at).label("latest_date")
    )

    if role == "patient":
        patient = Patient.query.filter_by(user_id=user_id).first()
        if not patient:
            return error_response("Patient profile not found")
        query = query.filter(PatientMedicalResult.patient_id == patient.patient_id)
    elif role == "doctor":
        doctor = Doctor.query.filter_by(user_id=user_id).first()
        if not doctor:
            return error_response("Doctor profile not found")
        patient_ids = [
            a.patient_id
            for a in PatientDoctorAssignment.query.filter_by(
                doctor_id=doctor.doctor_id, is_active=True
            ).all()
        ]
        if patient_ids:
            query = query.filter(PatientMedicalResult.patient_id.in_(patient_ids))

    rows = query.group_by(PatientMedicalResult.patient_id).all()

    data = []
    for r in rows:
        patient = Patient.query.get(r.patient_id)
        if patient:
            data.append({
                "patient_id": patient.patient_id,
                "patient_name": f"{patient.user.first_name} {patient.user.last_name}" if patient.user else "",
                "patient_code": patient.patient_code,
                "result_count": r.count,
                "latest_date": r.latest_date.isoformat() if r.latest_date else None
            })
    data.sort(key=lambda x: x["patient_name"])
    return success_response(data=data)


@patient_results_bp.route("/summary", methods=["GET"])
@role_required("secretary")
def results_summary():
    from ..models.medical_test import MedicalTest
    rows = db.session.query(
        PatientMedicalResult.test_id,
        func.count(PatientMedicalResult.result_id).label("count"),
        func.max(PatientMedicalResult.created_at).label("latest_date")
    ).group_by(PatientMedicalResult.test_id).all()

    data = []
    for r in rows:
        test = MedicalTest.query.get(r.test_id)
        if test:
            data.append({
                "test_code": test.test_code,
                "test_name": test.test_name,
                "default_unit": test.default_unit,
                "count": r.count,
                "latest_date": r.latest_date.isoformat() if r.latest_date else None
            })
    data.sort(key=lambda x: x["test_code"])
    return success_response(data=data)


@patient_results_bp.route("/by-test/<test_code>", methods=["GET"])
@role_required("secretary")
def results_by_test(test_code):
    from ..models.medical_test import MedicalTest
    test = MedicalTest.query.filter_by(test_code=test_code.upper()).first()
    if not test:
        return not_found_response("Test not found")
    results = PatientMedicalResult.query.filter_by(test_id=test.test_id).order_by(
        PatientMedicalResult.created_at.desc()
    ).all()
    return success_response(data=[r.to_dict() for r in results])


@patient_results_bp.route("/<int:result_id>", methods=["GET"])
@any_authenticated()
def get_result(result_id):
    claims = get_jwt()
    role = claims.get("role")
    user_id = claims.get("user_id")

    result = PatientMedicalResult.query.get(result_id)
    if not result:
        return not_found_response("Result not found")

    if role == "patient":
        patient = Patient.query.filter_by(user_id=user_id).first()
        if not patient or result.patient_id != patient.patient_id:
            return forbidden_response()

    return success_response(data=result.to_dict())
