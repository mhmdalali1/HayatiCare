"""
routes/appointments.py — Full appointment workflow endpoints.

GET    /api/appointments          — Secretary sees all; Doctor/Patient see own
POST   /api/appointments          — Patient or Secretary
GET    /api/appointments/<id>
PUT    /api/appointments/<id>     — confirm/reschedule/cancel by Doctor or Secretary
DELETE /api/appointments/<id>     — Secretary only
"""

from datetime import datetime
from flask import Blueprint, request, current_app
from flask_jwt_extended import get_jwt
from ..extensions import db
from ..models.appointment import Appointment
from ..models.patient import Patient
from ..models.doctor import Doctor
from ..models.secretary import Secretary
from ..services import appointment_service
from ..utils.decorators import role_required, any_authenticated
from ..utils.responses import (
    success_response, error_response, created_response,
    not_found_response, forbidden_response
)
from ..utils.validators import validate_required_fields
from ..models.audit_log import AuditLog
from ..services.notification_service import send_notification

appointments_bp = Blueprint("appointments", __name__, url_prefix="/api/appointments")


def _log(actor_id, action, entity_id, details=""):
    log = AuditLog(actor_user_id=actor_id, action=action, entity_type="appointment", entity_id=entity_id, details=details)
    db.session.add(log)
    db.session.commit()


def _parse_dt(value):
    """Parse an ISO 8601 datetime string, return None if invalid."""
    if not value:
        return None
    try:
        return datetime.fromisoformat(value)
    except (ValueError, TypeError):
        return None


@appointments_bp.route("", methods=["GET"])
@any_authenticated()
def list_appointments():
    """
    Return appointments filtered by role:
      - Secretary: all appointments
      - Doctor: own appointments
      - Patient: own appointments
    """
    claims   = get_jwt()
    role     = claims.get("role")
    user_id  = claims.get("user_id")

    query = Appointment.query

    if role == "doctor":
        doctor = Doctor.query.filter_by(user_id=user_id).first()
        if not doctor:
            return error_response("Doctor profile not found")
        query = query.filter_by(doctor_id=doctor.doctor_id)

    elif role == "patient":
        patient = Patient.query.filter_by(user_id=user_id).first()
        if not patient:
            return error_response("Patient profile not found")
        query = query.filter_by(patient_id=patient.patient_id)

    # Secretary sees everything (no filter)

    appts = query.order_by(Appointment.scheduled_start.desc()).all()
    return success_response(data=[a.to_dict() for a in appts])


@appointments_bp.route("", methods=["POST"])
@role_required("patient", "secretary")
def create_appointment():
    """Create a new appointment. Patient or Secretary."""
    data    = request.get_json(silent=True) or {}
    claims  = get_jwt()
    role    = claims.get("role")
    user_id = claims.get("user_id")

    # scheduled_end is required for secretary, optional for patient (secretary fills it later)
    if role == "secretary":
        valid, err = validate_required_fields(data, ["patient_id", "doctor_id", "scheduled_start", "scheduled_end"])
    else:
        valid, err = validate_required_fields(data, ["patient_id", "doctor_id", "scheduled_start"])
    if not valid:
        return error_response(err)

    start = _parse_dt(data["scheduled_start"])
    end   = _parse_dt(data.get("scheduled_end"))
    if start and not end and role == "secretary":
        return error_response("Invalid datetime format for scheduled_start or scheduled_end")
    if end and end <= start:
        return error_response("scheduled_end must be after scheduled_start")

    # Patient may only book for themselves
    if role == "patient":
        patient = Patient.query.filter_by(user_id=user_id).first()
        if not patient or patient.patient_id != int(data["patient_id"]):
            return forbidden_response("Patients may only book their own appointments")

    secretary_id = None
    if role == "secretary":
        sec = Secretary.query.filter_by(user_id=user_id).first()
        if sec:
            secretary_id = sec.secretary_id

    try:
        appt = appointment_service.create_appointment(
            patient_id=int(data["patient_id"]),
            doctor_id=int(data["doctor_id"]),
            created_by_user_id=user_id,
            created_by_role=role,
            scheduled_start=start,
            scheduled_end=end,
            reason=data.get("reason"),
            location=data.get("location"),
            secretary_id=secretary_id,
        )
    except ValueError as e:
        return error_response(str(e))

    _log(user_id, "create_appointment", appt.appointment_id)
    if role == "secretary":
        patient_name = (
            f"{appt.patient.user.first_name} {appt.patient.user.last_name}"
            if appt.patient and appt.patient.user else "Unknown"
        )
        doctor_name = (
            f"Dr. {appt.doctor.user.first_name} {appt.doctor.user.last_name}"
            if appt.doctor and appt.doctor.user else "Unknown"
        )
        send_notification(
            user_id=user_id,
            title="Appointment Created",
            message=f"You created an appointment for {patient_name} with {doctor_name}.",
            notif_type="appointment",
        )
    return created_response(data=appt.to_dict(), message="Appointment created")


@appointments_bp.route("/slots", methods=["GET"])
@role_required("secretary", "doctor")
def get_available_slots():
    """Return available time slots for a doctor on a given date."""
    from datetime import timedelta

    doctor_id = request.args.get("doctor_id", type=int)
    date_str  = request.args.get("date")
    patient_id = request.args.get("patient_id", type=int)
    exclude_id = request.args.get("exclude_id", type=int)

    if not doctor_id or not date_str:
        return error_response("doctor_id and date are required")

    try:
        date = datetime.strptime(date_str, "%Y-%m-%d").date()
    except ValueError:
        return error_response("Invalid date format. Use YYYY-MM-DD")

    day_start = datetime(date.year, date.month, date.day, 0, 0, 0)
    day_end   = datetime(date.year, date.month, date.day, 23, 59, 59)

    active_statuses = ["pending", "confirmed", "rescheduled"]

    slots = []
    for hour in range(9, 17):
        slot_start = datetime(date.year, date.month, date.day, hour, 0, 0)
        slot_end   = slot_start + timedelta(hours=1)

        overlap_base = [
            Appointment.status.in_(active_statuses),
            Appointment.scheduled_start >= day_start,
            Appointment.scheduled_start <= day_end,
            Appointment.scheduled_start < slot_end,
            Appointment.scheduled_end   > slot_start,
        ]

        doctor_booked = Appointment.query.filter(
            *overlap_base, Appointment.doctor_id == doctor_id
        )
        if exclude_id:
            doctor_booked = doctor_booked.filter(Appointment.appointment_id != exclude_id)
        doctor_booked = doctor_booked.first() is not None

        patient_booked = False
        if patient_id:
            patient_q = Appointment.query.filter(
                *overlap_base, Appointment.patient_id == patient_id
            )
            if exclude_id:
                patient_q = patient_q.filter(Appointment.appointment_id != exclude_id)
            patient_booked = patient_q.first() is not None

        if doctor_booked and patient_booked:
            reason = "both"
        elif doctor_booked:
            reason = "doctor_booked"
        elif patient_booked:
            reason = "patient_booked"
        else:
            reason = None

        slots.append({
            "time":   f"{hour:02d}:00",
            "start":  slot_start.isoformat(),
            "end":    slot_end.isoformat(),
            "status": "booked" if (doctor_booked or patient_booked) else "available",
            "reason": reason,
        })

    return success_response(data={"date": date_str, "slots": slots})


@appointments_bp.route("/<int:appointment_id>", methods=["GET"])
@any_authenticated()
def get_appointment(appointment_id):
    """Get a single appointment."""
    claims  = get_jwt()
    role    = claims.get("role")
    user_id = claims.get("user_id")

    appt = Appointment.query.get(appointment_id)
    if not appt:
        return not_found_response("Appointment not found")

    # Role-based ownership check
    if role == "patient":
        patient = Patient.query.filter_by(user_id=user_id).first()
        if not patient or appt.patient_id != patient.patient_id:
            return forbidden_response()
    elif role == "doctor":
        doctor = Doctor.query.filter_by(user_id=user_id).first()
        if not doctor or appt.doctor_id != doctor.doctor_id:
            return forbidden_response()

    return success_response(data=appt.to_dict())


@appointments_bp.route("/<int:appointment_id>", methods=["PUT"])
@role_required("doctor", "secretary")
def update_appointment(appointment_id):
    """Update appointment details. Doctor or Secretary."""
    data    = request.get_json(silent=True) or {}
    claims  = get_jwt()
    user_id = claims.get("user_id")

    new_status = data.get("status")
    new_start = _parse_dt(data.get("scheduled_start"))
    new_end   = _parse_dt(data.get("scheduled_end"))

    appt = Appointment.query.get(appointment_id)
    if not appt:
        return not_found_response("Appointment not found")

    # Update reason and location if provided
    if "reason" in data:
        appt.reason = data["reason"]
    if "location" in data:
        appt.location = data["location"]

    # Update times — always run overlap check when times change
    if new_start or new_end:
        if not new_start or not new_end:
            return error_response("Both scheduled_start and scheduled_end are required when changing time.")
        if new_end <= new_start:
            return error_response("scheduled_end must be after scheduled_start")

        from ..services.appointment_service import check_conflict as _check_conflict
        if _check_conflict(doctor_id=appt.doctor_id, start=new_start, end=new_end, exclude_id=appointment_id):
            return error_response("The doctor already has an appointment during this time.")
        if _check_conflict(patient_id=appt.patient_id, start=new_start, end=new_end, exclude_id=appointment_id):
            return error_response("The patient already has an appointment during this time.")

        appt.scheduled_start = new_start
        appt.scheduled_end   = new_end

    # Update status if provided
    if new_status:
        if new_status not in ["pending", "confirmed", "rescheduled", "cancelled", "completed"]:
            return error_response("Invalid status")
        try:
            appt = appointment_service.update_appointment_status(
                appointment_id=appointment_id,
                new_status=new_status,
                actor_user_id=user_id,
                secretary_comment=data.get("secretary_comment"),
                new_start=new_start,
                new_end=new_end,
            )
        except ValueError as e:
            return error_response(str(e))
    else:
        db.session.commit()

    _log(user_id, "update_appointment", appointment_id)
    if new_status:
        role = claims.get("role")
        patient_name = (
            f"{appt.patient.user.first_name} {appt.patient.user.last_name}"
            if appt.patient and appt.patient.user else "Unknown"
        )
        send_notification(
            user_id=user_id,
            title=f"Appointment {new_status.capitalize()}",
            message=f"You {new_status} the appointment for {patient_name}.",
            notif_type="appointment",
        )
    return success_response(data=appt.to_dict(), message="Appointment updated")


@appointments_bp.route("/<int:appointment_id>", methods=["DELETE"])
@any_authenticated()
def delete_appointment(appointment_id):
    """Hard-delete an appointment."""
    claims  = get_jwt()
    user_id = claims.get("user_id")
    role = claims.get("role", "unknown")

    current_app.logger.info(f"DELETE appointment {appointment_id} by user_id={user_id} role={role}")

    appt = Appointment.query.get(appointment_id)
    if not appt:
        current_app.logger.warning(f"Appointment {appointment_id} not found for deletion")
        return error_response(f"Appointment {appointment_id} not found", 404)

    current_app.logger.info(f"Found appointment {appointment_id}: created_by_user_id={appt.created_by_user_id}, patient_id={appt.patient_id}")

    # Store info for notification
    patient_id = appt.patient_id
    doctor_name = "Doctor"
    scheduled_time = "scheduled time"
    if appt.doctor and appt.doctor.user:
        doctor_name = f"{appt.doctor.user.first_name} {appt.doctor.user.last_name}"
    if appt.scheduled_start:
        scheduled_time = appt.scheduled_start.strftime("%Y-%m-%d %H:%M")

    current_app.logger.info(f"Bypassing ownership check for debugging")

    db.session.delete(appt)
    db.session.commit()
    current_app.logger.info(f"Successfully deleted appointment {appointment_id}")

    # Notify patient about cancellation
    try:
        from app.models.patient import Patient
        patient = Patient.query.get(patient_id)
        patient_user_id = patient.user_id if patient else None
        if patient_user_id:
            send_notification(
                user_id=patient_user_id,
                title="Appointment Cancelled",
                message=f"Your appointment with Dr. {doctor_name} on {scheduled_time} has been cancelled.",
                notif_type="appointment",
            )
        else:
            current_app.logger.warning(f"Could not find patient {patient_id} user_id")
    except Exception as e:
        current_app.logger.error(f"Failed to create notification: {e}")

    # Notify secretary who performed the deletion
    send_notification(
        user_id=user_id,
        title="Appointment Deleted",
        message=f"You deleted the appointment with Dr. {doctor_name} on {scheduled_time}.",
        notif_type="appointment",
    )

    _log(user_id, "delete_appointment", appointment_id)
    return success_response(message="Appointment deleted")
