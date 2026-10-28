"""
services/auth_service.py — Authentication business logic.

Handles login, JWT creation, password hashing, and account lockout.
Account lockout tracking is stored in memory (a simple dict) as specified.
"""

import bcrypt
from flask_jwt_extended import create_access_token, create_refresh_token
from ..models.user import User
from ..extensions import db

# In-memory failed-login counter: { email: consecutive_failure_count }
_failed_attempts: dict = {}

# Maximum consecutive failures before locking the account
MAX_FAILED_ATTEMPTS = 3


def hash_password(plain_text: str) -> str:
    """Hash a plain-text password with bcrypt and return the hash string."""
    hashed = bcrypt.hashpw(plain_text.encode("utf-8"), bcrypt.gensalt())
    return hashed.decode("utf-8")


def verify_password(plain_text: str, hashed: str) -> bool:
    """Return True if plain_text matches the stored bcrypt hash."""
    return bcrypt.checkpw(plain_text.encode("utf-8"), hashed.encode("utf-8"))


def attempt_login(email: str, password: str):
    """
    Attempt to authenticate a user by email and password.

    Business rules:
      - Account must exist and be active (is_active=True).
      - After 3 consecutive failures the account is locked (is_active set False).
      - Successful login resets the failure counter.

    Returns:
        (user, access_token, refresh_token) on success
        (None, None, None)                  on failure
    Raises:
        ValueError with a descriptive message on locked or unknown accounts.
    """
    user = User.query.filter_by(email=email).first()

    if user is None:
        # Increment counter even for non-existent email to prevent enumeration
        _failed_attempts[email] = _failed_attempts.get(email, 0) + 1
        raise ValueError("Invalid email or password")

    if not user.is_active:
        raise ValueError("Account is locked. Please contact the administrator.")

    if not verify_password(password, user.password_hash):
        count = _failed_attempts.get(email, 0) + 1
        _failed_attempts[email] = count

        if count >= MAX_FAILED_ATTEMPTS:
            # Lock the account
            user.is_active = False
            db.session.commit()
            raise ValueError(
                "Account locked after too many failed attempts. Contact the administrator."
            )

        remaining = MAX_FAILED_ATTEMPTS - count
        raise ValueError(
            f"Invalid email or password. {remaining} attempt(s) remaining before lockout."
        )

    # Success — reset failure counter and issue tokens
    _failed_attempts.pop(email, None)

    additional_claims = {
        "role":     user.role,
        "user_id":  user.user_id,
        "email":    user.email,
    }
    access_token  = create_access_token(identity=str(user.user_id), additional_claims=additional_claims)
    refresh_token = create_refresh_token(identity=str(user.user_id), additional_claims=additional_claims)

    return user, access_token, refresh_token


def unlock_account(email: str):
    """Re-activate a locked account and clear its failure counter."""
    user = User.query.filter_by(email=email).first()
    if user:
        user.is_active = True
        db.session.commit()
        _failed_attempts.pop(email, None)


def initiate_password_reset(email: str) -> str:
    """
    Stub: generate a password reset token.
    In production, this would send an email.
    Returns the token string (printed to logs for development).
    """
    user = User.query.filter_by(email=email).first()
    if not user:
        # Do not reveal whether the email exists
        return None

    # Generate a one-time token (using JWT for simplicity)
    token = create_access_token(
        identity=str(user.user_id),
        additional_claims={"purpose": "password_reset"},
    )
    # STUB: print instead of sending email
    print(f"[DEV] Password reset token for {email}: {token}")
    return token


def confirm_password_reset(token: str, new_password: str):
    """
    Confirm a password reset using the provided token and set the new password.
    Returns True on success, raises ValueError on invalid token.
    """
    from flask_jwt_extended import decode_token

    try:
        decoded = decode_token(token)
    except Exception:
        raise ValueError("Invalid or expired reset token")

    if decoded.get("purpose") != "password_reset":
        raise ValueError("Invalid reset token purpose")

    user_id = int(decoded["sub"])
    user = User.query.get(user_id)
    if not user:
        raise ValueError("User not found")

    user.password_hash = hash_password(new_password)
    db.session.commit()
    return True
