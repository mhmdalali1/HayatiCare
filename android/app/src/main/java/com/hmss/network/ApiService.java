package com.hmss.network;

import com.hmss.models.Appointment;
import com.hmss.models.Notification;
import com.hmss.models.TestResult;
import com.hmss.models.User;

import java.util.List;
import java.util.Map;

import retrofit2.Call;
import retrofit2.http.Body;
import retrofit2.http.DELETE;
import retrofit2.http.GET;
import retrofit2.http.POST;
import retrofit2.http.PUT;
import retrofit2.http.Path;

/**
 * ApiService — Retrofit interface declaring all HMSS backend endpoints.
 *
 * Each method corresponds to one API endpoint.
 * All responses are wrapped in ApiResponse<T> which mirrors:
 *   { "success": bool, "data": T, "message": string }
 */
public interface ApiService {

    // ── AUTH ─────────────────────────────────────────────────────────────

    /** POST /api/auth/login */
    @POST("api/auth/login")
    Call<ApiResponse<LoginData>> login(@Body Map<String, String> body);

    /** POST /api/auth/logout */
    @POST("api/auth/logout")
    Call<ApiResponse<Void>> logout();

    /** POST /api/auth/refresh */
    @POST("api/auth/refresh")
    Call<ApiResponse<TokenData>> refreshToken();

    /** POST /api/auth/register — patient self-registration */
    @POST("api/auth/register")
    Call<ApiResponse<LoginData>> register(@Body Map<String, String> body);

    /** POST /api/auth/reset-password-request */
    @POST("api/auth/reset-password-request")
    Call<ApiResponse<Void>> resetPasswordRequest(@Body Map<String, String> body);

    // ── PATIENTS ──────────────────────────────────────────────────────────

    /** GET /api/patients/me — returns the patient profile of the logged-in user */
    @GET("api/patients/me")
    Call<ApiResponse<PatientProfile>> getMyProfile();

    /** GET /api/patients/<id> */
    @GET("api/patients/{id}")
    Call<ApiResponse<User>> getPatient(@Path("id") int patientId);

    /** GET /api/patients/<id>/appointments */
    @GET("api/patients/{id}/appointments")
    Call<ApiResponse<List<Appointment>>> getPatientAppointments(@Path("id") int patientId);

    /** GET /api/patients/<id>/test-results */
    @GET("api/patients/{id}/test-results")
    Call<ApiResponse<List<TestResult>>> getPatientTestResults(@Path("id") int patientId);

    /** GET /api/patients/<id>/medical-history */
    @GET("api/patients/{id}/medical-history")
    Call<ApiResponse<MedicalHistory>> getMedicalHistory(@Path("id") int patientId);

    /** POST /api/patients/<id>/home-tests */
    @POST("api/patients/{id}/home-tests")
    Call<ApiResponse<TestResult>> submitHomeTest(@Path("id") int patientId, @Body Map<String, Object> body);

    // ── APPOINTMENTS ──────────────────────────────────────────────────────

    /** GET /api/appointments */
    @GET("api/appointments")
    Call<ApiResponse<List<Appointment>>> getAppointments();

    /** POST /api/appointments */
    @POST("api/appointments")
    Call<ApiResponse<Appointment>> createAppointment(@Body Map<String, Object> body);

    /** GET /api/appointments/<id> */
    @GET("api/appointments/{id}")
    Call<ApiResponse<Appointment>> getAppointment(@Path("id") int id);

    // ── TEST RESULTS ──────────────────────────────────────────────────────

    /** GET /api/test-results */
    @GET("api/test-results")
    Call<ApiResponse<List<TestResult>>> getTestResults();

    /** GET /api/test-results/<id> */
    @GET("api/test-results/{id}")
    Call<ApiResponse<TestResult>> getTestResult(@Path("id") int id);

    // ── NOTIFICATIONS ─────────────────────────────────────────────────────

    /** GET /api/notifications */
    @GET("api/notifications")
    Call<ApiResponse<List<Notification>>> getNotifications();

    /** PUT /api/notifications/<id>/read */
    @PUT("api/notifications/{id}/read")
    Call<ApiResponse<Notification>> markNotificationRead(@Path("id") int id);

    /** DELETE /api/notifications/<id> */
    @DELETE("api/notifications/{id}")
    Call<ApiResponse<Void>> deleteNotification(@Path("id") int id);

    // ── CHATBOT ───────────────────────────────────────────────────────────

    /** POST /api/chatbot/query */
    @POST("api/chatbot/query")
    Call<ApiResponse<ChatbotResponse>> chatbotQuery(@Body Map<String, String> body);

    /** GET /api/chatbot/faqs */
    @GET("api/chatbot/faqs")
    Call<ApiResponse<FaqTopics>> getChatbotFaqs();

    // ── MEDICAL TESTS ─────────────────────────────────────────────────────

    /** GET /api/medical-tests */
    @GET("api/medical-tests")
    Call<ApiResponse<List<Map<String, Object>>>> getMedicalTests();

    // ─────────────────────────────────────────────────────────────────────
    // Inner helper data classes (used only for response typing)
    // ─────────────────────────────────────────────────────────────────────

    /** Generic API response envelope. */
    class ApiResponse<T> {
        public boolean success;
        public T data;
        public String message;
    }

    /** Data returned on successful login. */
    class LoginData {
        public String access_token;
        public String refresh_token;
        public User user;
    }

    /** Data returned on token refresh. */
    class TokenData {
        public String access_token;
    }

    /** Medical history bundle. */
    class MedicalHistory {
        public User patient;
        public List<Appointment> appointments;
        public List<TestResult> test_results;
    }

    /** Chatbot query response. */
    class ChatbotResponse {
        public String response_text;
        public Integer faq_id;
        public Integer test_id;
    }

    /** FAQ topics list. */
    class FaqTopics {
        public List<String> topics;
    }

    /** Patient profile returned by /api/patients/me. */
    class PatientProfile {
        public int patient_id;
        public int user_id;
    }
}
