package com.hmss.models;

import com.google.gson.annotations.SerializedName;

/**
 * Appointment — represents a scheduled patient-doctor meeting.
 */
public class Appointment {

    @SerializedName("appointment_id")   public int    appointmentId;
    @SerializedName("patient_id")       public int    patientId;
    @SerializedName("doctor_id")        public int    doctorId;
    @SerializedName("patient_name")     public String patientName;
    @SerializedName("doctor_name")      public String doctorName;
    @SerializedName("scheduled_start")  public String scheduledStart;
    @SerializedName("scheduled_end")    public String scheduledEnd;
    @SerializedName("status")           public String status;
    @SerializedName("reason")           public String reason;
    @SerializedName("location")         public String location;
    @SerializedName("secretary_comment")public String secretaryComment;

    /**
     * Return a display-safe start time string.
     * The ISO string from the API is used directly here; format it in the UI layer.
     */
    public String getDisplayStart() {
        return scheduledStart != null ? scheduledStart : "TBD";
    }
}
