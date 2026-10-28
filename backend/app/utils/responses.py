"""
utils/responses.py — Standard JSON response helpers.

All API responses follow the envelope:
  Success: { "success": true,  "data": {...},  "message": "..." }
  Error:   { "success": false, "data": null,   "message": "..." }
"""

from flask import jsonify


def success_response(data=None, message="OK", status_code=200):
    """Return a standardised success JSON response."""
    return jsonify({"success": True, "data": data, "message": message}), status_code


def error_response(message="An error occurred", status_code=400):
    """Return a standardised error JSON response."""
    return jsonify({"success": False, "data": None, "message": message}), status_code


def created_response(data=None, message="Created"):
    """Convenience wrapper for HTTP 201 Created."""
    return success_response(data=data, message=message, status_code=201)


def not_found_response(message="Resource not found"):
    """Convenience wrapper for HTTP 404 Not Found."""
    return error_response(message=message, status_code=404)


def forbidden_response(message="Access denied"):
    """Convenience wrapper for HTTP 403 Forbidden."""
    return error_response(message=message, status_code=403)


def unauthorized_response(message="Unauthorized"):
    """Convenience wrapper for HTTP 401 Unauthorized."""
    return error_response(message=message, status_code=401)
