"""
app/__init__.py — Flask application factory.

Creates and configures the Flask app, registers extensions and blueprints.
"""

from flask import Flask, send_from_directory
from flask_cors import CORS

from .extensions import db, jwt, migrate
from config import config_map
import os


def create_app(env: str = "development") -> Flask:
    """
    Application factory.

    Args:
        env: Configuration environment name ('development' or 'production').

    Returns:
        A fully configured Flask application instance.
    """
    app = Flask(__name__)

    # Load configuration
    cfg_class = config_map.get(env, config_map["development"])
    app.config.from_object(cfg_class)

    # Initialise extensions
    db.init_app(app)
    jwt.init_app(app)
    migrate.init_app(app, db)
    CORS(app, resources={
        r"/api/*": {
            "origins": ["*"],
            "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
            "allow_headers": ["Content-Type", "Authorization"],
        }
    })

    # Register all models (ensures they are known to SQLAlchemy)
    with app.app_context():
        from .models import (  # noqa: F401
            User, Patient, Doctor, Secretary,
            PatientDoctorAssignment, Appointment,
            MedicalTest, TestNormalRange, TestResult,
            Notification, AuditLog, ChatbotFaqEntry, ChatQueryLog,
            BodyHealth,
            PatientMedicalResult,
        )
        from sqlalchemy import inspect, text
        try:
            inspector = inspect(db.engine)
            cols = [c["name"] for c in inspector.get_columns("patient_medical_result")]
            if "batch_id" not in cols:
                with db.engine.connect() as conn:
                    conn.execute(text("ALTER TABLE patient_medical_result ADD COLUMN batch_id INT NULL"))
                    conn.commit()
        except Exception:
            pass

        # Ensure body_health table exists (may be missing if schema wasn't fully applied)
        try:
            tables = inspect(db.engine).get_table_names()
            if "body_health" not in tables:
                with db.engine.connect() as conn:
                    conn.execute(text("""
                        CREATE TABLE IF NOT EXISTS body_health (
                            body_health_id INT AUTO_INCREMENT PRIMARY KEY,
                            patient_id INT NOT NULL,
                            gender VARCHAR(10),
                            height_cm DECIMAL(5,2),
                            weight_kg DECIMAL(5,2),
                            bmi DECIMAL(4,2),
                            bmi_category VARCHAR(30),
                            daily_calorie_limit INT,
                            last_updated DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                            CONSTRAINT fk_bh_patient FOREIGN KEY (patient_id) REFERENCES patient(patient_id) ON DELETE CASCADE
                        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
                    """))
                    conn.commit()
        except Exception:
            pass

    # Register route blueprints
    from .routes.auth          import auth_bp
    from .routes.patients      import patients_bp
    from .routes.doctors       import doctors_bp
    from .routes.secretary     import secretary_bp
    from .routes.appointments  import appointments_bp
    from .routes.test_results  import test_results_bp
    from .routes.notifications import notifications_bp
    from .routes.chatbot       import chatbot_bp
    from .routes.medical_tests import medical_tests_bp
    from .routes.body_health   import body_health_bp
    from .routes.patient_results import patient_results_bp
    from .routes.audit         import audit_bp
    from .routes.chat          import chat_bp

    app.register_blueprint(auth_bp)
    app.register_blueprint(patients_bp)
    app.register_blueprint(doctors_bp)
    app.register_blueprint(secretary_bp)
    app.register_blueprint(appointments_bp)
    app.register_blueprint(test_results_bp)
    app.register_blueprint(notifications_bp)
    app.register_blueprint(chatbot_bp)
    app.register_blueprint(medical_tests_bp)
    app.register_blueprint(body_health_bp)
    app.register_blueprint(patient_results_bp)
    app.register_blueprint(audit_bp)
    app.register_blueprint(chat_bp)

    # Serve static web files AFTER API blueprints
    # Absolute path to web folder
    web_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "..", "web")
    web_dir = os.path.normpath(web_dir)
    if os.path.exists(web_dir):
        @app.route("/")
        def index():
            return send_from_directory(web_dir, "index.html")

        @app.route("/<path:filename>")
        def serve_web(filename):
            if filename.startswith("api/"):
                return "Not Found", 404
            path = os.path.join(web_dir, filename)
            if os.path.isdir(path):
                index_path = os.path.join(path, "index.html")
                if os.path.exists(index_path):
                    return send_from_directory(path, "index.html")
            if os.path.exists(path):
                return send_from_directory(web_dir, filename)
            return send_from_directory(web_dir, "index.html")

        @app.route("/secretary/results/<test_code>")
        def secretary_test_detail(test_code):
            page = os.path.join(web_dir, "secretary", "test_detail.html")
            if os.path.exists(page):
                return send_from_directory(os.path.join(web_dir, "secretary"), "test_detail.html")
            return send_from_directory(web_dir, "index.html")

    # JWT error handlers — return standard JSON responses
    @jwt.unauthorized_loader
    def missing_token_callback(reason):
        from .utils.responses import unauthorized_response
        return unauthorized_response(f"Missing or invalid token: {reason}")

    @jwt.invalid_token_loader
    def invalid_token_callback(reason):
        from .utils.responses import unauthorized_response
        return unauthorized_response(f"Invalid token: {reason}")

    @jwt.expired_token_loader
    def expired_token_callback(jwt_header, jwt_payload):
        from .utils.responses import unauthorized_response
        return unauthorized_response("Token has expired")

    return app