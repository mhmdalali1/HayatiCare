"""
extensions.py — Initialises Flask extensions as module-level singletons.

Extensions are created here without binding to a specific Flask app instance.
They are initialised with the app object inside create_app() in __init__.py,
following the Application Factory pattern.
"""

from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager
from flask_migrate import Migrate

# SQLAlchemy ORM instance
db = SQLAlchemy()

# JWT manager for token creation and validation
jwt = JWTManager()

# Flask-Migrate for database migrations
migrate = Migrate()
