"""
models/__init__.py — Imports all ORM models so they are registered with SQLAlchemy.
"""

from .body_health import BodyHealth
from .user import User
from .patient import Patient
from .doctor import Doctor
from .secretary import Secretary
from .patient_doctor_assignment import PatientDoctorAssignment
from .appointment import Appointment
from .medical_test import MedicalTest
from .test_normal_range import TestNormalRange
from .test_result import TestResult
from .notification import Notification
from .audit_log import AuditLog
from .chatbot_faq_entry import ChatbotFaqEntry
from .chat_query_log import ChatQueryLog
from .patient_medical_result import PatientMedicalResult
