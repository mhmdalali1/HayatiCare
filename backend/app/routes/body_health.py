"""
routes/body_health.py — Body health metrics endpoints.
"""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import get_jwt, jwt_required
from ..extensions import db
from ..models.body_health import BodyHealth
from ..models.patient import Patient
from ..utils.responses import (
    success_response, error_response, created_response,
    not_found_response, forbidden_response
)
from ..utils.decorators import role_required, any_authenticated


body_health_bp = Blueprint("body_health", __name__, url_prefix="/api/body-health")


@body_health_bp.route("/patient/<int:patient_id>", methods=["GET"])
@any_authenticated()
def get_body_health(patient_id):
    """Get body health record for a patient."""
    claims = get_jwt()
    role = claims.get("role")
    user_id = claims.get("user_id")

    patient = Patient.query.get(patient_id)
    if not patient:
        return not_found_response("Patient not found")

    # Patients can only view their own record
    if role == "patient" and patient.user_id != user_id:
        return forbidden_response()

    record = BodyHealth.query.filter_by(patient_id=patient_id).first()
    if not record:
        return not_found_response("Body health record not found")

    return success_response(data=record.to_dict())


@body_health_bp.route("/patient/<int:patient_id>", methods=["POST"])
@role_required("secretary")
def create_body_health(patient_id):
    """Create body health record. Secretary only."""
    data = request.get_json(silent=True) or {}
    claims = get_jwt()
    actor_id = claims.get("user_id")

    patient = Patient.query.get(patient_id)
    if not patient:
        return not_found_response("Patient not found")

    # Check if record already exists
    existing = BodyHealth.query.filter_by(patient_id=patient_id).first()
    if existing:
        return error_response("Body health record already exists. Use PUT to update.")

    record = BodyHealth(
        patient_id=patient_id,
        height_cm=data.get("height_cm"),
        weight_kg=data.get("weight_kg"),
        bmi=data.get("bmi"),
        bmi_category=data.get("bmi_category"),
        daily_calorie_limit=data.get("daily_calorie_limit"),
    )
    db.session.add(record)
    db.session.commit()

    return created_response(data=record.to_dict(), message="Body health record created")


@body_health_bp.route("/patient/<int:patient_id>", methods=["PUT"])
@jwt_required()
def update_body_health(patient_id):
    """Update body health record. Patient can update their own, secretary can update any."""
    data = request.get_json(silent=True) or {}
    claims = get_jwt()
    role = claims.get("role")
    user_id = claims.get("user_id")

    patient = Patient.query.get(patient_id)
    if not patient:
        return not_found_response("Patient not found")

    # Check permissions
    if role == "patient" and patient.user_id != user_id:
        return forbidden_response()

    record = BodyHealth.query.filter_by(patient_id=patient_id).first()
    if not record:
        # Auto-create if doesn't exist and patient is updating
        if role == "patient":
            record = BodyHealth(patient_id=patient_id)
            db.session.add(record)
        else:
            return not_found_response("Body health record not found")

    # Update fields
    for field in ["gender", "height_cm", "weight_kg", "bmi", "bmi_category", "daily_calorie_limit"]:
        if field in data:
            setattr(record, field, data[field])

    db.session.commit()
    return success_response(data=record.to_dict(), message="Body health record updated")


@body_health_bp.route("/patient/<int:patient_id>", methods=["DELETE"])
@role_required("secretary")
def delete_body_health(patient_id):
    """Delete body health record. Secretary only."""
    record = BodyHealth.query.filter_by(patient_id=patient_id).first()
    if not record:
        return not_found_response("Body health record not found")

    db.session.delete(record)
    db.session.commit()
    return success_response(message="Body health record deleted")
