"""
models/test_normal_range.py — Normal range boundaries for a medical test.
"""

from ..extensions import db


class TestNormalRange(db.Model):
    """Stores the population-specific normal range for a medical test."""

    __tablename__ = "test_normal_range"

    range_id       = db.Column(db.Integer, primary_key=True, autoincrement=True)
    test_id        = db.Column(db.Integer, db.ForeignKey("medical_test.test_id", ondelete="CASCADE"), nullable=False)
    population     = db.Column(db.String(50))
    sex            = db.Column(db.String(10))
    min_age_years  = db.Column(db.Numeric(5, 2))
    max_age_years  = db.Column(db.Numeric(5, 2))
    fasting_state  = db.Column(db.String(20))
    min_value      = db.Column(db.Numeric(12, 4))
    max_value      = db.Column(db.Numeric(12, 4))
    unit           = db.Column(db.String(30))
    range_note     = db.Column(db.Text)
    effective_from = db.Column(db.DateTime)
    effective_to   = db.Column(db.DateTime)
    created_at     = db.Column(db.DateTime, server_default=db.func.current_timestamp())
    updated_at     = db.Column(
        db.DateTime,
        server_default=db.func.current_timestamp(),
        onupdate=db.func.current_timestamp(),
    )

    # Relationships
    test         = db.relationship("MedicalTest", back_populates="normal_ranges")
    test_results = db.relationship("TestResult",  back_populates="applied_range", lazy="dynamic")

    def to_dict(self):
        """Return a dictionary representation."""
        return {
            "range_id":       self.range_id,
            "test_id":        self.test_id,
            "population":     self.population,
            "sex":            self.sex,
            "min_age_years":  float(self.min_age_years) if self.min_age_years is not None else None,
            "max_age_years":  float(self.max_age_years) if self.max_age_years is not None else None,
            "fasting_state":  self.fasting_state,
            "min_value":      float(self.min_value)     if self.min_value     is not None else None,
            "max_value":      float(self.max_value)     if self.max_value     is not None else None,
            "unit":           self.unit,
            "range_note":     self.range_note,
            "effective_from": self.effective_from.isoformat() if self.effective_from else None,
            "effective_to":   self.effective_to.isoformat()   if self.effective_to   else None,
        }

    def __repr__(self):
        return f"<TestNormalRange test={self.test_id} [{self.min_value}–{self.max_value} {self.unit}]>"
