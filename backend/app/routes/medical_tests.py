"""
routes/medical_tests.py — Medical test catalogue and normal ranges.

GET /api/medical-tests
GET /api/medical-tests/<id>
GET /api/medical-tests/<id>/ranges
"""

from flask import Blueprint
from ..models.medical_test import MedicalTest
from ..models.test_normal_range import TestNormalRange
from ..utils.decorators import any_authenticated
from ..utils.responses import success_response, not_found_response

medical_tests_bp = Blueprint("medical_tests", __name__, url_prefix="/api/medical-tests")


@medical_tests_bp.route("", methods=["GET"])
@any_authenticated()
def list_tests():
    """List all active medical tests."""
    tests = MedicalTest.query.filter_by(is_active=True).all()
    return success_response(data=[t.to_dict() for t in tests])


@medical_tests_bp.route("/<int:test_id>", methods=["GET"])
@any_authenticated()
def get_test(test_id):
    """Get details for a single medical test."""
    test = MedicalTest.query.get(test_id)
    if not test:
        return not_found_response("Medical test not found")
    return success_response(data=test.to_dict())


@medical_tests_bp.route("/<int:test_id>/ranges", methods=["GET"])
@any_authenticated()
def get_test_ranges(test_id):
    """Get all normal ranges for a medical test."""
    test = MedicalTest.query.get(test_id)
    if not test:
        return not_found_response("Medical test not found")

    ranges = TestNormalRange.query.filter_by(test_id=test_id).all()
    return success_response(data=[r.to_dict() for r in ranges])
