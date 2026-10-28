"""
routes/auth.py — Authentication endpoints.

POST /api/auth/login
POST /api/auth/logout
POST /api/auth/refresh
POST /api/auth/reset-password-request
POST /api/auth/reset-password-confirm
"""

from flask import Blueprint, request
from flask_jwt_extended import (
    jwt_required,
    get_jwt_identity,
    get_jwt,
    create_access_token,
)
from ..services import auth_service
from ..utils.responses import success_response, error_response, created_response
from ..utils.validators import validate_email, validate_required_fields
from ..extensions import db
from ..models.user import User
from ..models.patient import Patient
from .patients import _generate_patient_code

auth_bp = Blueprint("auth", __name__, url_prefix="/api/auth")


@auth_bp.route("/login", methods=["POST"])
def login():
    """Authenticate a user and return JWT access + refresh tokens."""
    data = request.get_json(silent=True) or {}
    email    = data.get("email", "").strip().lower()
    password = data.get("password", "")

    valid, err = validate_email(email)
    if not valid:
        return error_response(err)

    try:
        user, access_token, refresh_token = auth_service.attempt_login(email, password)
    except ValueError as e:
        return error_response(str(e), 401)

    return success_response(
        data={
            "access_token":  access_token,
            "refresh_token": refresh_token,
            "user":          user.to_dict(),
        },
        message="Login successful",
    )


@auth_bp.route("/logout", methods=["POST"])
@jwt_required()
def logout():
    """
    Logout is handled client-side by discarding the token.
    This endpoint exists for completeness / future token blacklisting.
    """
    return success_response(message="Logged out successfully")


@auth_bp.route("/refresh", methods=["POST"])
@jwt_required(refresh=True)
def refresh():
    """Issue a new access token using a valid refresh token."""
    identity = get_jwt_identity()
    claims   = get_jwt()
    new_token = create_access_token(
        identity=identity,
        additional_claims={
            "role":    claims.get("role"),
            "user_id": claims.get("user_id"),
            "email":   claims.get("email"),
        },
    )
    return success_response(data={"access_token": new_token}, message="Token refreshed")


@auth_bp.route("/register", methods=["POST"])
def register():
    """Public patient self-registration."""
    data = request.get_json(silent=True) or {}

    required = ["email", "password", "first_name", "last_name"]
    valid, err = validate_required_fields(data, required)
    if not valid:
        return error_response(err)

    valid, err = validate_email(data["email"])
    if not valid:
        return error_response(err)

    if User.query.filter_by(email=data["email"].strip().lower()).first():
        return error_response("Email already registered")

    user = User(
        role="patient",
        first_name=data["first_name"],
        last_name=data["last_name"],
        email=data["email"].strip().lower(),
        phone=data.get("phone"),
        password_hash=auth_service.hash_password(data["password"]),
    )
    db.session.add(user)
    db.session.flush()

    dob = data.get("date_of_birth")
    if dob == "" or dob is None:
        dob = None

    patient = Patient(
        user_id=user.user_id,
        patient_code=_generate_patient_code(),
        date_of_birth=dob,
        gender=data.get("gender"),
        blood_type=data.get("blood_type"),
    )
    db.session.add(patient)
    db.session.commit()

    access_token, refresh_token = _issue_tokens(user)
    return created_response(data={
        "access_token": access_token,
        "refresh_token": refresh_token,
        "user": user.to_dict(),
    }, message="Account created successfully")


def _issue_tokens(user):
    from flask_jwt_extended import create_access_token, create_refresh_token
    claims = {"role": user.role, "user_id": user.user_id, "email": user.email}
    return (
        create_access_token(identity=str(user.user_id), additional_claims=claims),
        create_refresh_token(identity=str(user.user_id), additional_claims=claims),
    )


@auth_bp.route("/reset-password-request", methods=["POST"])
def reset_password_request():
    """Request a password reset for the given email address."""
    data  = request.get_json(silent=True) or {}
    email = data.get("email", "").strip().lower()

    valid, err = validate_email(email)
    if not valid:
        return error_response(err)

    auth_service.initiate_password_reset(email)
    # Always return success to prevent email enumeration
    return success_response(message="If that email exists, a reset link has been sent.")


@auth_bp.route("/reset-password-confirm", methods=["POST"])
def reset_password_confirm():
    """Confirm a password reset using the token and new password."""
    data         = request.get_json(silent=True) or {}
    token        = data.get("token", "")
    new_password = data.get("new_password", "")

    if not token or not new_password:
        return error_response("Token and new_password are required")

    try:
        auth_service.confirm_password_reset(token, new_password)
    except ValueError as e:
        return error_response(str(e))

    return success_response(message="Password reset successfully")
