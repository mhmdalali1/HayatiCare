"""
services/test_validation_service.py — Auto-flag abnormal test results.

When a test result is uploaded:
  1. Look up the patient's age, sex, and fasting state.
  2. Find the best-matching TEST_NORMAL_RANGE row.
  3. Compare result.value against min/max.
  4. Set is_flagged and status accordingly.
  5. Save applied_range_id and validated_at.
  6. If flagged, send notifications to patient and doctor.
"""

from datetime import datetime, date
from ..extensions import db
from ..models.test_result import TestResult
from ..models.test_normal_range import TestNormalRange
from ..models.patient import Patient
from .notification_service import send_notification


def _calculate_age(dob: date) -> float:
    """Return age in years as a float from a date of birth."""
    today = date.today()
    return (today - dob).days / 365.25


def find_best_range(test_id: int, patient: Patient, fasting_state: str):
    """
    Find the most specific TestNormalRange for a given test and patient profile.

    Matching priority (all filters applied simultaneously then relaxed):
      1. sex + age + fasting_state match
      2. sex + age match (any fasting)
      3. age match only
      4. Any active range for the test
    Returns the first matching TestNormalRange or None.
    """
    gender = patient.gender  # 'male' | 'female' | other
    dob = patient.date_of_birth
    age = _calculate_age(dob) if dob else None

    base_query = TestNormalRange.query.filter_by(test_id=test_id)

    # Build increasingly relaxed queries
    for try_fasting in [fasting_state, None]:
        for try_sex in [gender, None]:
            q = base_query
            if try_sex:
                q = q.filter(
                    (TestNormalRange.sex == try_sex) | (TestNormalRange.sex.is_(None))
                )
            if try_fasting:
                q = q.filter(
                    (TestNormalRange.fasting_state == try_fasting) |
                    (TestNormalRange.fasting_state.is_(None))
                )
            if age is not None:
                q = q.filter(
                    (TestNormalRange.min_age_years <= age) | (TestNormalRange.min_age_years.is_(None))
                ).filter(
                    (TestNormalRange.max_age_years >= age) | (TestNormalRange.max_age_years.is_(None))
                )
            result = q.first()
            if result:
                return result

    return None


def validate_and_flag(result: TestResult):
    """
    Validate a test result against the appropriate normal range.

    Mutates the result object in place:
      - Sets applied_range_id, is_flagged, status, validated_at, validation_method.
    Commits the changes to the database.
    If flagged, sends notifications to both patient and doctor.

    Args:
        result: A persisted TestResult ORM object.
    """
    patient = result.patient
    normal_range = find_best_range(result.test_id, patient, result.fasting_state)

    result.validated_at = datetime.utcnow()
    if not result.validation_method:
        result.validation_method = "auto"

    if normal_range is None:
        # No range found — leave as pending, cannot determine normality
        result.status = "pending"
        result.is_flagged = False
        result.validation_note = "No matching normal range found for this patient profile"
        db.session.commit()
        return

    result.applied_range_id = normal_range.range_id
    value = float(result.value) if result.value is not None else None

    if value is None:
        result.status = "pending"
        result.is_flagged = False
    elif (normal_range.min_value is not None and value < float(normal_range.min_value)) or \
         (normal_range.max_value is not None and value > float(normal_range.max_value)):
        # Abnormal result
        result.is_flagged = True
        result.status = "abnormal"
    else:
        result.is_flagged = False
        result.status = "normal"

    db.session.commit()

    # Send notifications when flagged
    if result.is_flagged:
        test_name = result.test.test_name if result.test else "Test"
        patient_user_id = patient.user.user_id if patient and patient.user else None
        doctor_user_id = result.doctor.user.user_id if result.doctor and result.doctor.user else None

        if patient_user_id:
            send_notification(
                user_id=patient_user_id,
                title="Abnormal Test Result",
                message=(
                    f"Your {test_name} result ({result.value} {result.unit}) "
                    f"is outside the normal range "
                    f"({normal_range.min_value}–{normal_range.max_value} {normal_range.unit}). "
                    f"Please consult your doctor."
                ),
                notif_type="test_result",
            )

        if doctor_user_id:
            patient_name = (
                f"{patient.user.first_name} {patient.user.last_name}"
                if patient and patient.user else "Unknown patient"
            )
            send_notification(
                user_id=doctor_user_id,
                title="Flagged Test Result",
                message=(
                    f"Patient {patient_name}'s {test_name} result "
                    f"({result.value} {result.unit}) is flagged as abnormal."
                ),
                notif_type="test_result",
            )
