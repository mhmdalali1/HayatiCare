from sqlalchemy.dialects.mysql import BIGINT
from ..extensions import db


class PatientMedicalResult(db.Model):
    __tablename__ = "patient_medical_result"

    result_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    patient_id = db.Column(db.Integer, db.ForeignKey("patient.patient_id"), nullable=False)
    test_id = db.Column(db.Integer, db.ForeignKey("medical_test.test_id"), nullable=False)
    value = db.Column(db.String(50), nullable=False)
    unit = db.Column(db.String(30))
    status = db.Column(db.String(20), default="normal")
    created_by_user_id = db.Column(db.Integer, db.ForeignKey("user.user_id"))
    batch_id = db.Column(BIGINT(unsigned=False), index=True)
    created_at = db.Column(db.DateTime, server_default=db.func.current_timestamp())

    patient = db.relationship("Patient", backref=db.backref("patient_medical_results", lazy="dynamic"))
    test = db.relationship("MedicalTest")
    created_by = db.relationship("User")

    def to_dict(self):
        return {
            "result_id": self.result_id,
            "patient_id": self.patient_id,
            "test_id": self.test_id,
            "value": self.value,
            "unit": self.unit,
            "status": self.status,
            "created_by_user_id": self.created_by_user_id,
            "batch_id": self.batch_id,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "test_code": self.test.test_code if self.test else None,
            "test_name": self.test.test_name if self.test else None,
            "default_unit": self.test.default_unit if self.test else None,
            "patient_name": (
                f"{self.patient.user.first_name} {self.patient.user.last_name}"
                if self.patient and self.patient.user else None
            ),
            "patient_code": self.patient.patient_code if self.patient else None,
        }

    def __repr__(self):
        return f"<PatientMedicalResult {self.result_id} patient={self.patient_id} test={self.test_id}>"
