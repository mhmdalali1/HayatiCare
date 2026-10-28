"""
seed_data.py — Create all test accounts and sample data.

Usage (from backend/ with a local disposable database):
    Set DEMO_SEED_PASSWORD (minimum 12 characters) in the environment,
    then run: python seed_data.py

Safe to run multiple times — existing records are updated, not duplicated.
"""

import os
import sys
from datetime import datetime, date, timedelta

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import create_app
from app.extensions import db
from app.models.user import User
from app.models.patient import Patient
from app.models.doctor import Doctor
from app.models.secretary import Secretary
from app.models.medical_test import MedicalTest
from app.models.test_normal_range import TestNormalRange
from app.models.patient_doctor_assignment import PatientDoctorAssignment
from app.models.appointment import Appointment
from app.models.test_result import TestResult
from app.models.notification import Notification
from app.models.chatbot_faq_entry import ChatbotFaqEntry
from app.services.auth_service import hash_password

PASSWORD = os.environ.get("DEMO_SEED_PASSWORD")
if not PASSWORD or len(PASSWORD) < 12:
    raise SystemExit(
        "Set DEMO_SEED_PASSWORD to a unique password of at least 12 characters "
        "before generating disposable demonstration accounts."
    )

app = create_app("development")


def get_or_create_user(email, role, first_name, last_name, phone=None):
    user = User.query.filter_by(email=email).first()
    if user:
        user.password_hash = hash_password(PASSWORD)
        user.first_name = first_name
        user.last_name = last_name
        user.is_active = True
        print(f"  [updated] {email}")
    else:
        user = User(
            role=role,
            first_name=first_name,
            last_name=last_name,
            email=email,
            phone=phone,
            password_hash=hash_password(PASSWORD),
            is_active=True,
        )
        db.session.add(user)
        print(f"  [created] {email}")
    db.session.flush()
    return user


with app.app_context():
    print("\n── Users ──────────────────────────────────────")

    # ── Secretary ───────────────────────────────────
    sec_user = get_or_create_user(
        "secretary@hmss.com", "secretary", "Sara", "Mansour", "0501000001"
    )
    sec = Secretary.query.filter_by(user_id=sec_user.user_id).first()
    if not sec:
        sec = Secretary(user_id=sec_user.user_id, employee_code="SEC-001")
        db.session.add(sec)

    # ── Doctors ─────────────────────────────────────
    doc1_user = get_or_create_user(
        "dr.smith@hmss.com", "doctor", "James", "Smith", "0501000002"
    )
    doc1 = Doctor.query.filter_by(user_id=doc1_user.user_id).first()
    if not doc1:
        doc1 = Doctor(
            user_id=doc1_user.user_id,
            specialization="Cardiology",
            license_number="LIC-1001",
            office_room="A101",
        )
        db.session.add(doc1)
    db.session.flush()

    doc2_user = get_or_create_user(
        "dr.jones@hmss.com", "doctor", "Emily", "Jones", "0501000003"
    )
    doc2 = Doctor.query.filter_by(user_id=doc2_user.user_id).first()
    if not doc2:
        doc2 = Doctor(
            user_id=doc2_user.user_id,
            specialization="General Medicine",
            license_number="LIC-1002",
            office_room="B205",
        )
        db.session.add(doc2)
    db.session.flush()

    # ── Patients ─────────────────────────────────────
    p1_user = get_or_create_user(
        "patient1@hmss.com", "patient", "Ali", "Hassan", "0501000004"
    )
    p1 = Patient.query.filter_by(user_id=p1_user.user_id).first()
    if not p1:
        p1 = Patient(
            user_id=p1_user.user_id,
            patient_code="PAT-001",
            national_id="NID-001",
            date_of_birth=date(1990, 5, 15),
            gender="male",
            blood_type="A+",
            address="123 Main St, Beirut",
        )
        db.session.add(p1)
    db.session.flush()

    p2_user = get_or_create_user(
        "patient2@hmss.com", "patient", "Sara", "Ahmad", "0501000005"
    )
    p2 = Patient.query.filter_by(user_id=p2_user.user_id).first()
    if not p2:
        p2 = Patient(
            user_id=p2_user.user_id,
            patient_code="PAT-002",
            national_id="NID-002",
            date_of_birth=date(1985, 8, 22),
            gender="female",
            blood_type="B+",
            address="456 Oak Ave, Tripoli",
        )
        db.session.add(p2)
    db.session.flush()

    p3_user = get_or_create_user(
        "patient3@hmss.com", "patient", "Omar", "Khalil", "0501000006"
    )
    p3 = Patient.query.filter_by(user_id=p3_user.user_id).first()
    if not p3:
        p3 = Patient(
            user_id=p3_user.user_id,
            patient_code="PAT-003",
            national_id="NID-003",
            date_of_birth=date(2000, 3, 10),
            gender="male",
            blood_type="O+",
            address="789 Pine Rd, Sidon",
        )
        db.session.add(p3)
    db.session.flush()

    db.session.commit()
    print("\n── Medical Tests ───────────────────────────────")

    tests_data = [
        ("GLU",  "Blood Glucose",        "mmol/L",  "Metabolic"),
        ("HGB",  "Hemoglobin",           "g/dL",    "Hematology"),
        ("CHOL", "Total Cholesterol",    "mmol/L",  "Lipid Panel"),
        ("WBC",  "White Blood Cells",    "10^9/L",  "Hematology"),
        ("BP",   "Blood Pressure",       "mmHg",    "Cardiovascular"),
        ("PLT",  "Platelets",            "10^9/L",  "Hematology"),
        ("NA",   "Sodium",               "mmol/L",  "Electrolyte"),
        ("K",    "Potassium",            "mmol/L",  "Electrolyte"),
        ("CRE",  "Creatinine",           "mg/dL",   "Renal"),
        ("ALT",  "Alanine Transaminase", "U/L",     "Liver"),
        ("AST",  "Aspartate Transaminase","U/L",    "Liver"),
        ("SPO2", "Oxygen Saturation",    "%",       "Respiratory"),
        ("TEMP", "Temperature",          "°C",      "Vitals"),
    ]

    tests = {}
    for code, name, unit, cat in tests_data:
        t = MedicalTest.query.filter_by(test_code=code).first()
        if not t:
            t = MedicalTest(test_code=code, test_name=name, default_unit=unit, category=cat)
            db.session.add(t)
            print(f"  [created] {name}")
        else:
            print(f"  [exists]  {name}")
        db.session.flush()
        tests[code] = t

    db.session.commit()
    print("\n── Normal Ranges ───────────────────────────────")

    ranges_data = [
        # (test_code, sex, min_age, max_age, fasting, min_val, max_val, unit)
        ("GLU",  None,     0,  120, "fasting",      3.9,   5.5,   "mmol/L"),
        ("GLU",  None,     0,  120, "non-fasting",  4.4,   7.8,   "mmol/L"),
        ("HGB",  "male",   18, 120, None,          13.5,  17.5,   "g/dL"),
        ("HGB",  "female", 18, 120, None,          12.0,  15.5,   "g/dL"),
        ("HGB",  None,      0,  17,  None,          11.0,  16.0,   "g/dL"),
        ("CHOL", None,     18, 120, None,           0.0,   5.2,   "mmol/L"),
        ("WBC",  None,      0, 120, None,           4.0,  11.0,   "10^9/L"),
        ("BP",   None,     18, 120, None,          60.0, 120.0,   "mmHg"),
        ("PLT",  None,      0, 120, None,         150.0, 450.0,   "10^9/L"),
        ("NA",   None,      0, 120, None,         135.0, 145.0,   "mmol/L"),
        ("K",    None,      0, 120, None,           3.5,   5.0,   "mmol/L"),
        ("CRE",  "male",   18, 120, None,           0.7,   1.3,   "mg/dL"),
        ("CRE",  "female", 18, 120, None,           0.6,   1.1,   "mg/dL"),
        ("ALT",  None,      0, 120, None,           7.0,  56.0,   "U/L"),
        ("AST",  None,      0, 120, None,          10.0,  40.0,   "U/L"),
        ("SPO2", None,      0, 120, None,          95.0, 100.0,   "%"),
        ("TEMP", None,      0, 120, None,          36.1,  37.2,   "°C"),
    ]

    for code, sex, min_age, max_age, fasting, min_v, max_v, unit in ranges_data:
        test = tests[code]
        exists = TestNormalRange.query.filter_by(
            test_id=test.test_id, sex=sex, fasting_state=fasting,
            min_age_years=min_age, max_age_years=max_age
        ).first()
        if not exists:
            r = TestNormalRange(
                test_id=test.test_id,
                sex=sex,
                min_age_years=min_age,
                max_age_years=max_age,
                fasting_state=fasting,
                min_value=min_v,
                max_value=max_v,
                unit=unit,
            )
            db.session.add(r)
            print(f"  [created] {code} range ({sex or 'any'}, {fasting or 'any fasting'})")

    db.session.commit()

    # Re-fetch doctors and patients after commit
    doc1 = Doctor.query.filter_by(user_id=doc1_user.user_id).first()
    doc2 = Doctor.query.filter_by(user_id=doc2_user.user_id).first()
    p1   = Patient.query.filter_by(user_id=p1_user.user_id).first()
    p2   = Patient.query.filter_by(user_id=p2_user.user_id).first()
    p3   = Patient.query.filter_by(user_id=p3_user.user_id).first()

    print("\n── Patient-Doctor Assignments ──────────────────")
    for patient, doctor in [(p1, doc1), (p2, doc1), (p3, doc2)]:
        exists = PatientDoctorAssignment.query.filter_by(
            patient_id=patient.patient_id, doctor_id=doctor.doctor_id
        ).first()
        if not exists:
            a = PatientDoctorAssignment(
                patient_id=patient.patient_id,
                doctor_id=doctor.doctor_id,
                created_by_user_id=sec_user.user_id,
                is_active=True,
            )
            db.session.add(a)
            print(f"  [created] {patient.user.first_name} → Dr. {doctor.user.last_name}")

    db.session.commit()

    print("\n── Appointments ────────────────────────────────")
    now = datetime.utcnow()
    appointments_data = [
        (p1, doc1, now + timedelta(days=3),  now + timedelta(days=3,  hours=1), "confirmed",  "Routine checkup"),
        (p2, doc1, now + timedelta(days=5),  now + timedelta(days=5,  hours=1), "pending",    "Follow-up visit"),
        (p3, doc2, now - timedelta(days=7),  now - timedelta(days=7) + timedelta(hours=1), "completed", "Annual physical"),
        (p1, doc1, now - timedelta(days=14), now - timedelta(days=14) + timedelta(hours=1), "cancelled", "Cancelled by patient"),
    ]

    for patient, doctor, start, end, status, reason in appointments_data:
        exists = Appointment.query.filter_by(
            patient_id=patient.patient_id,
            doctor_id=doctor.doctor_id,
            scheduled_start=start,
        ).first()
        if not exists:
            appt = Appointment(
                patient_id=patient.patient_id,
                doctor_id=doctor.doctor_id,
                created_by_user_id=sec_user.user_id,
                created_by_role="secretary",
                scheduled_start=start,
                scheduled_end=end,
                status=status,
                reason=reason,
            )
            db.session.add(appt)
            print(f"  [created] {patient.user.first_name} + Dr.{doctor.user.last_name} [{status}]")

    db.session.commit()

    print("\n── Test Results ────────────────────────────────")
    results_data = [
        (p1, doc1, "GLU",  5.1,  "mmol/L", "fasting",     "normal"),
        (p1, doc1, "HGB",  14.2, "g/dL",   None,          "normal"),
        (p2, doc1, "GLU",  8.5,  "mmol/L", "non-fasting", "abnormal"),  # flagged
        (p2, doc1, "CHOL", 6.1,  "mmol/L", None,          "abnormal"),  # flagged
        (p3, doc2, "WBC",  7.3,  "10^9/L", None,          "normal"),
        (p3, doc2, "HGB",  10.5, "g/dL",   None,          "abnormal"),  # flagged
    ]

    for patient, doctor, code, value, unit, fasting, status in results_data:
        test = tests[code]
        exists = TestResult.query.filter_by(
            patient_id=patient.patient_id,
            test_id=test.test_id,
            value=value,
        ).first()
        if not exists:
            tr = TestResult(
                patient_id=patient.patient_id,
                doctor_id=doctor.doctor_id,
                test_id=test.test_id,
                value=value,
                unit=unit,
                fasting_state=fasting,
                result_date=now - timedelta(days=2),
                status=status,
                is_flagged=(status == "abnormal"),
                validation_method="auto",
                validated_at=now,
            )
            db.session.add(tr)
            flag = " ⚠" if status == "abnormal" else ""
            print(f"  [created] {patient.user.first_name} {code}={value}{flag}")

    db.session.commit()

    print("\n── Chatbot FAQ ─────────────────────────────────")
    faqs = [
        (tests["GLU"].test_id,  "Blood Glucose", "What is the normal blood glucose level?",
         "Fasting blood glucose: 3.9–5.5 mmol/L. Non-fasting: 4.4–7.8 mmol/L. Values above these may indicate diabetes."),
        (tests["HGB"].test_id,  "Hemoglobin",    "What is a normal hemoglobin level?",
         "Normal hemoglobin: Men 13.5–17.5 g/dL, Women 12.0–15.5 g/dL. Low levels may indicate anaemia."),
        (tests["CHOL"].test_id, "Cholesterol",   "What is a healthy cholesterol level?",
         "Total cholesterol below 5.2 mmol/L is considered healthy. High levels increase heart disease risk."),
        (None, "App Usage", "How do I book an appointment?",
         "Go to the Appointments section, click 'New Appointment', fill in the doctor and time, then submit."),
        (None, "App Usage", "How do I view my test results?",
         "Go to Test Results in the menu. Flagged results are highlighted in red and require attention."),
    ]

    for test_id, topic, question, answer in faqs:
        exists = ChatbotFaqEntry.query.filter_by(question=question).first()
        if not exists:
            faq = ChatbotFaqEntry(
                test_id=test_id,
                topic=topic,
                question=question,
                answer=answer,
                is_active=True,
            )
            db.session.add(faq)
            print(f"  [created] {topic}: {question[:50]}...")

    db.session.commit()

    print("\n✅ Seed complete!\n")
    print("  Role       │ Email                  │ Password")
    print("  ───────────┼────────────────────────┼──────────")
    print("  Secretary  │ secretary@hmss.com      │ 00000000")
    print("  Doctor     │ dr.smith@hmss.com       │ 00000000")
    print("  Doctor     │ dr.jones@hmss.com       │ 00000000")
    print("  Patient    │ patient1@hmss.com       │ 00000000")
    print("  Patient    │ patient2@hmss.com       │ 00000000")
    print("  Patient    │ patient3@hmss.com       │ 00000000")
    print()
