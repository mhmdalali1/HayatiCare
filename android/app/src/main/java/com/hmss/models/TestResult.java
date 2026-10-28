package com.hmss.models;

import com.google.gson.annotations.SerializedName;

/**
 * TestResult — a single medical test measurement for a patient.
 */
public class TestResult {

    @SerializedName("result_id")    public int     resultId;
    @SerializedName("patient_id")   public int     patientId;
    @SerializedName("doctor_id")    public int     doctorId;
    @SerializedName("test_id")      public int     testId;
    @SerializedName("test_name")    public String  testName;
    @SerializedName("test_code")    public String  testCode;
    @SerializedName("patient_name") public String  patientName;
    @SerializedName("result_date")  public String  resultDate;
    @SerializedName("value")        public double  value;
    @SerializedName("unit")         public String  unit;
    @SerializedName("fasting_state")public String  fastingState;
    @SerializedName("status")       public String  status;
    @SerializedName("is_flagged")   public boolean isFlagged;
    @SerializedName("notes")        public String  notes;
    @SerializedName("normal_range") public NormalRange normalRange;

    /** Embedded normal range info returned in result detail. */
    public static class NormalRange {
        @SerializedName("min_value")  public double minValue;
        @SerializedName("max_value")  public double maxValue;
        @SerializedName("unit")       public String unit;

        /** Human-readable range string, e.g. "3.9–5.5 mmol/L" */
        public String getDisplayRange() {
            return minValue + "–" + maxValue + " " + unit;
        }
    }
}
