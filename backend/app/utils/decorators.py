"""
utils/decorators.py — Custom Flask route decorators.

Provides @role_required(role) to enforce role-based access control
on top of flask_jwt_extended's @jwt_required().
"""

from functools import wraps
from flask_jwt_extended import verify_jwt_in_request, get_jwt
from .responses import forbidden_response, unauthorized_response


def role_required(*allowed_roles):
    """
    Decorator that ensures the authenticated user has one of the allowed roles.

    Usage:
        @role_required("doctor")
        @role_required("doctor", "secretary")

    The JWT payload must contain a 'role' claim set at login time.
    Returns 401 if no valid token, 403 if role is not permitted.
    """
    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            # Validate JWT token (raises exception → handled by JWT error handlers)
            try:
                verify_jwt_in_request()
            except Exception:
                return unauthorized_response("Authentication required")

            # Check role claim
            claims = get_jwt()
            user_role = claims.get("role", "")
            if user_role not in allowed_roles:
                return forbidden_response(
                    f"Access denied. Required role: {' or '.join(allowed_roles)}"
                )

            return fn(*args, **kwargs)
        return wrapper
    return decorator


def any_authenticated():
    """
    Decorator that only checks for a valid JWT without restricting by role.
    Returns 401 if no valid token is present.
    """
    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            try:
                verify_jwt_in_request()
            except Exception:
                return unauthorized_response("Authentication required")
            return fn(*args, **kwargs)
        return wrapper
    return decorator
