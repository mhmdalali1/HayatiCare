package com.hmss;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.hmss.models.User;
import com.hmss.network.ApiClient;
import com.hmss.network.ApiService;
import com.google.gson.Gson;

import java.util.HashMap;
import java.util.Map;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

/**
 * LoginActivity — Email + password login form.
 *
 * On success:
 *   - Saves access_token, refresh_token, and user JSON to SharedPreferences.
 *   - Sets token in ApiClient.
 *   - Navigates to PatientDashboardActivity.
 */
public class LoginActivity extends AppCompatActivity {

    private EditText etEmail, etPassword;
    private Button   btnLogin;
    private TextView tvError;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_login);

        etEmail   = findViewById(R.id.et_email);
        etPassword= findViewById(R.id.et_password);
        btnLogin  = findViewById(R.id.btn_login);
        tvError   = findViewById(R.id.tv_error);

        btnLogin.setOnClickListener(v -> attemptLogin());

        TextView tvSignUp = findViewById(R.id.tv_sign_up);
        if (tvSignUp != null) {
            tvSignUp.setOnClickListener(v ->
                startActivity(new Intent(LoginActivity.this, SignUpActivity.class)));
        }

        TextView tvReset = findViewById(R.id.tv_forgot_password);
        if (tvReset != null) {
            tvReset.setOnClickListener(v ->
                Toast.makeText(this, "Contact your administrator to reset your password.", Toast.LENGTH_LONG).show()
            );
        }
    }

    /**
     * Validate fields and call the login API.
     */
    private void attemptLogin() {
        String email    = etEmail.getText().toString().trim();
        String password = etPassword.getText().toString();

        tvError.setVisibility(View.GONE);

        // Basic client-side validation
        if (TextUtils.isEmpty(email)) {
            tvError.setText("Email is required");
            tvError.setVisibility(View.VISIBLE);
            return;
        }
        if (TextUtils.isEmpty(password)) {
            tvError.setText("Password is required");
            tvError.setVisibility(View.VISIBLE);
            return;
        }

        btnLogin.setEnabled(false);

        Map<String, String> body = new HashMap<>();
        body.put("email",    email);
        body.put("password", password);

        ApiClient.getService().login(body).enqueue(new Callback<ApiService.ApiResponse<ApiService.LoginData>>() {

            @Override
            public void onResponse(Call<ApiService.ApiResponse<ApiService.LoginData>> call,
                                   Response<ApiService.ApiResponse<ApiService.LoginData>> response) {
                btnLogin.setEnabled(true);

                if (response.isSuccessful() && response.body() != null) {
                    ApiService.ApiResponse<ApiService.LoginData> res = response.body();

                    if (res.success && res.data != null) {
                        // Only patients can use the mobile app
                        if (res.data.user != null && !"patient".equals(res.data.user.role)) {
                            tvError.setText("This app is for patients only. Please use the web portal.");
                            tvError.setVisibility(View.VISIBLE);
                            return;
                        }

                        SharedPreferences prefs = getSharedPreferences("hmss_prefs", MODE_PRIVATE);
                        prefs.edit()
                            .putString("access_token",  res.data.access_token)
                            .putString("refresh_token", res.data.refresh_token)
                            .putString("user_json",     new Gson().toJson(res.data.user))
                            .apply();

                        ApiClient.setAccessToken(res.data.access_token);

                        // Fetch the patient_id (different from user_id) and store it
                        // before navigating, so home-test and appointment screens work.
                        ApiClient.getService().getMyProfile().enqueue(
                            new retrofit2.Callback<ApiService.ApiResponse<ApiService.PatientProfile>>() {
                                @Override
                                public void onResponse(
                                        retrofit2.Call<ApiService.ApiResponse<ApiService.PatientProfile>> call,
                                        retrofit2.Response<ApiService.ApiResponse<ApiService.PatientProfile>> r) {
                                    if (r.isSuccessful() && r.body() != null
                                            && r.body().success && r.body().data != null) {
                                        prefs.edit()
                                            .putInt("patient_id", r.body().data.patient_id)
                                            .apply();
                                    }
                                    startActivity(new Intent(LoginActivity.this, PatientDashboardActivity.class));
                                    finish();
                                }
                                @Override
                                public void onFailure(
                                        retrofit2.Call<ApiService.ApiResponse<ApiService.PatientProfile>> call,
                                        Throwable t) {
                                    // Navigate anyway; patient_id will be missing but the user
                                    // will see an error only when they try to submit a home test.
                                    startActivity(new Intent(LoginActivity.this, PatientDashboardActivity.class));
                                    finish();
                                }
                            }
                        );
                    } else {
                        tvError.setText(res.message != null ? res.message : "Login failed");
                        tvError.setVisibility(View.VISIBLE);
                    }
                } else {
                    tvError.setText("Server error. Please try again.");
                    tvError.setVisibility(View.VISIBLE);
                }
            }

            @Override
            public void onFailure(Call<ApiService.ApiResponse<ApiService.LoginData>> call, Throwable t) {
                btnLogin.setEnabled(true);
                tvError.setText("Cannot reach server: " + t.getMessage());
                tvError.setVisibility(View.VISIBLE);
            }
        });
    }
}
