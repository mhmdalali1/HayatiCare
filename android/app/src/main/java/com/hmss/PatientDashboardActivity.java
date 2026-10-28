package com.hmss;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.widget.Button;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;

import com.google.gson.Gson;
import com.hmss.models.User;
import com.hmss.network.ApiClient;

/**
 * PatientDashboardActivity — Home screen after successful login.
 *
 * Displays a welcome message and navigation buttons for:
 *   - Appointments
 *   - Test Results
 *   - Submit Home Test
 *   - Chatbot
 */
public class PatientDashboardActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_patient_dashboard);

        // Restore token if app was relaunched
        SharedPreferences prefs = getSharedPreferences("hmss_prefs", MODE_PRIVATE);
        String token = prefs.getString("access_token", null);
        if (token != null) ApiClient.setAccessToken(token);

        // Display patient name
        String userJson = prefs.getString("user_json", null);
        if (userJson != null) {
            User user = new Gson().fromJson(userJson, User.class);
            TextView tvWelcome = findViewById(R.id.tv_welcome);
            if (tvWelcome != null) {
                tvWelcome.setText("Welcome, " + user.getFullName());
            }
        }

        // Navigation buttons
        Button btnAppointments = findViewById(R.id.btn_appointments);
        if (btnAppointments != null) {
            btnAppointments.setOnClickListener(v ->
                startActivity(new Intent(this, AppointmentsActivity.class)));
        }

        Button btnTestResults = findViewById(R.id.btn_test_results);
        if (btnTestResults != null) {
            btnTestResults.setOnClickListener(v ->
                startActivity(new Intent(this, TestResultsActivity.class)));
        }

        Button btnHomeTest = findViewById(R.id.btn_home_test);
        if (btnHomeTest != null) {
            btnHomeTest.setOnClickListener(v ->
                startActivity(new Intent(this, HomeTestSubmitActivity.class)));
        }

        Button btnChatbot = findViewById(R.id.btn_chatbot);
        if (btnChatbot != null) {
            btnChatbot.setOnClickListener(v ->
                startActivity(new Intent(this, ChatbotActivity.class)));
        }

        // Logout button
        Button btnLogout = findViewById(R.id.btn_logout);
        if (btnLogout != null) {
            btnLogout.setOnClickListener(v -> {
                ApiClient.getService().logout().enqueue(new retrofit2.Callback<com.hmss.network.ApiService.ApiResponse<Void>>() {
                    @Override public void onResponse(retrofit2.Call<com.hmss.network.ApiService.ApiResponse<Void>> call, retrofit2.Response<com.hmss.network.ApiService.ApiResponse<Void>> response) {}
                    @Override public void onFailure(retrofit2.Call<com.hmss.network.ApiService.ApiResponse<Void>> call, Throwable t) {}
                });
                prefs.edit().clear().apply();
                ApiClient.clearToken();
                startActivity(new Intent(PatientDashboardActivity.this, LoginActivity.class));
                finish();
            });
        }
    }

}
