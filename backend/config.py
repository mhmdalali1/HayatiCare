"""
config.py — Flask application configuration.
Reads all sensitive values from environment variables (loaded via python-dotenv).
"""

import os
from datetime import timedelta
from dotenv import load_dotenv
from urllib.parse import quote

load_dotenv()


class Config:
    """Base configuration shared by all environments."""

    # Flask
    SECRET_KEY = os.environ.get("SECRET_KEY", "change-me-in-production")

    # Database — SQLAlchemy connection string
    db_password = quote(os.environ.get('DB_PASSWORD', ''))
    SQLALCHEMY_DATABASE_URI = (
        f"mysql+pymysql://{os.environ.get('DB_USER', 'hmss_user')}"
        f":{db_password}"
        f"@{os.environ.get('DB_HOST', 'localhost')}"
        f"/{os.environ.get('DB_NAME', 'hmss_db')}"
        f"?charset=utf8mb4"
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # JWT
    JWT_SECRET_KEY = os.environ.get("JWT_SECRET_KEY", "jwt-change-me-in-production")
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(
        seconds=int(os.environ.get("JWT_ACCESS_TOKEN_EXPIRES", 900))
    )
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(
        seconds=int(os.environ.get("JWT_REFRESH_TOKEN_EXPIRES", 604800))
    )
    JWT_TOKEN_LOCATION = ["headers"]
    JWT_HEADER_NAME = "Authorization"
    JWT_HEADER_TYPE = "Bearer"


class DevelopmentConfig(Config):
    """Development-specific settings."""
    DEBUG = True


class ProductionConfig(Config):
    """Production-specific settings."""
    DEBUG = False


# Map string names to config classes
config_map = {
    "development": DevelopmentConfig,
    "production": ProductionConfig,
}
