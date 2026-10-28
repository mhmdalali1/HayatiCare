"""
services/appointment_service.py — Appointment business logic.

Handles conflict checking, creation, status transitions, and notifications.
"""

from datetime import datetime
from ..extensions import db
from ..models.appointment import Appointment
from ..models.patient import Patient
from ..models.doctor import Doctor
from .notification_service import send_notification


# Valid status transitions
_VALID_STATUSES = {"pending", "confirmed", "rescheduled", "cancelled", "completed"}


def check_conflict(
    doctor_id: int = None,
    patient_id: int = None,
    start: datetime = None,
    end: datetime = None,
    exclude_id: int = None,
) -> bool:
    """
    Return True if the given time slot overlaps with an existing active appointment
    for the specified doctor OR patient.

    Overlap condition: existing.start < new.end AND existing.end > new.start

    Args:
        doctor_id:   The doctor to check against (optional).
        patient_id:  The patient to check against (optional).
        start:       Proposed appointment start datetime.
        end:         Proposed appointment end datetime.
        exclude_id:  Appointment ID to exclude (used when editing).
    """
    if not start or not end:
        return False

    filters = [
        Appointment.status.in_(["pending", "confirmed", "rescheduled"]),
        Appointment.scheduled_start < end,
        Appointment.scheduled_end   > start,
    ]
    if doctor_id is not None:
        filters.append(Appointment.doctor_id == doctor_id)
    if patient_id is not None:
        filters.append(Appointment.patient_id == patient_id)

    query = Appointment.query.filter(*filters)
    if exclude_id:
        query = query.filter(Appointment.appointment_id != exclude_id)

    return query.first() is not None


def create_appointment(
    patient_id: int,
    doctor_id: int,
    created_by_user_id: int,
    created_by_role: str,
    scheduled_start: datetime,
    scheduled_end: datetime = None,
    reason: str = None,
    location: str = None,
    secretary_id: int = None,
):
    """
    Create a new appointment after checking for scheduling conflicts.

    Returns the new Appointment object.
    Raises ValueError if the time slot is unavailable.
    """
    from datetime import timedelta
    # If no end time provided, default to 1 hour after start
    if scheduled_end is None:
        scheduled_end = scheduled_start + timedelta(hours=1)

    if scheduled_end:
        if check_conflict(doctor_id=doctor_id, start=scheduled_start, end=scheduled_end):
            raise ValueError("The doctor already has an appointment during this time.")
        if check_conflict(patient_id=patient_id, start=scheduled_start, end=scheduled_end):
            raise ValueError("You already have an appointment during this time.")

    appt = Appointment(
        patient_id=patient_id,
        doctor_id=doctor_id,
        created_by_user_id=created_by_user_id,
        created_by_role=created_by_role,
        managed_by_secretary_id=secretary_id,
        scheduled_start=scheduled_start,
        scheduled_end=scheduled_end,
        reason=reason,
        location=location,
        status="pending",
    )
    db.session.add(appt)
    db.session.commit()
    return appt


def update_appointment_status(
    appointment_id: int,
    new_status: str,
    actor_user_id: int,
    secretary_comment: str = None,
    new_start: datetime = None,
    new_end: datetime = None,
):
    """
    Update the status of an existing appointment.

    Sends notifications:
      - On confirmation → patient notified.
      - On cancellation → both patient and doctor notified.

    Returns the updated Appointment object.
    Raises ValueError on invalid status or conflict when rescheduling.
    """
    if new_status not in _VALID_STATUSES:
        raise ValueError(f"Invalid status '{new_status}'")

    appt = Appointment.query.get(appointment_id)
    if not appt:
        raise ValueError("Appointment not found")

    if new_start and new_end:
        if check_conflict(doctor_id=appt.doctor_id, start=new_start, end=new_end, exclude_id=appointment_id):
            raise ValueError("The doctor is not available during this time.")
        if check_conflict(patient_id=appt.patient_id, start=new_start, end=new_end, exclude_id=appointment_id):
            raise ValueError("The patient already has an appointment during this time.")
        appt.scheduled_start = new_start
        appt.scheduled_end   = new_end

    appt.status = new_status
    if secretary_comment:
        appt.secretary_comment = secretary_comment

    db.session.commit()

    # Resolve user IDs for notifications
    patient = appt.patient
    doctor  = appt.doctor
    patient_user_id = patient.user.user_id if patient and patient.user else None
    doctor_user_id  = doctor.user.user_id  if doctor  and doctor.user  else None

    if new_status == "confirmed" and patient_user_id:
        send_notification(
            user_id=patient_user_id,
            title="Appointment Confirmed",
            message=(
                f"Your appointment on "
                f"{appt.scheduled_start.strftime('%Y-%m-%d %H:%M') if appt.scheduled_start else 'TBD'} "
                f"has been confirmed."
            ),
            notif_type="appointment",
        )

    elif new_status == "cancelled":
        msg = f"Your appointment on {appt.scheduled_start.strftime('%Y-%m-%d %H:%M') if appt.scheduled_start else 'TBD'} has been cancelled."
        if patient_user_id:
            send_notification(patient_user_id, "Appointment Cancelled", msg, "appointment")
        if doctor_user_id:
            patient_name = (
                f"{patient.user.first_name} {patient.user.last_name}"
                if patient and patient.user else "Unknown patient"
            )
            send_notification(
                doctor_user_id,
                "Appointment Cancelled",
                f"Appointment with {patient_name} on {appt.scheduled_start.strftime('%Y-%m-%d %H:%M') if appt.scheduled_start else 'TBD'} has been cancelled.",
                "appointment",
            )

    return appt
