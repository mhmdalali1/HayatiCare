package com.hmss;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Spinner;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;

import com.google.gson.Gson;
import com.hmss.network.ApiClient;
import com.hmss.network.ApiService;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

/**
 * SignUpActivity — Patient self-registration form.
 */
public class SignUpActivity extends AppCompatActivity {

    private EditText etFirstName, etLastName, etEmail, etPassword,
                     etConfirmPassword, etPhone, etDob;
    private Spinner  spnGender, spnBlood;
    private TextView tvError;
    private Button   btnCreate;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_sign_up);

        etFirstName      = findViewById(R.id.et_first_name);
        etLastName       = findViewById(R.id.et_last_name);
        etEmail          = findViewById(R.id.et_email);
        etPassword       = findViewById(R.id.et_password);
        etConfirmPassword= findViewById(R.id.et_confirm_password);
        etPhone          = findViewById(R.id.et_phone);
        etDob            = findViewById(R.id.et_dob);
        spnGender        = findViewById(R.id.spn_gender);
        spnBlood         = findViewById(R.id.spn_blood);
        tvError          = findViewById(R.id.tv_error);
        btnCreate        = findViewById(R.id.btn_create_account);

        ArrayAdapter<String> genderAdapter = new ArrayAdapter<>(this,
            android.R.layout.simple_spinner_item,
            Arrays.asList("— Select Gender —", "male", "female", "other"));
        genderAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        spnGender.setAdapter(genderAdapter);

        ArrayAdapter<String> bloodAdapter = new ArrayAdapter<>(this,
            android.R.layout.simple_spinner_item,
            Arrays.asList("— Blood Type —", "A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"));
        bloodAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        spnBlood.setAdapter(bloodAdapter);

        btnCreate.setOnClickListener(v -> attemptRegister());

        TextView tvBack = findViewById(R.id.tv_back_to_login);
        if (tvBack != null) tvBack.setOnClickListener(v -> finish());
    }

    private void attemptRegister() {
        String firstName = etFirstName.getText().toString().trim();
        String lastName  = etLastName.getText().toString().trim();
        String email     = etEmail.getText().toString().trim();
        String password  = etPassword.getText().toString();
        String confirm   = etConfirmPassword.getText().toString();
        String phone     = etPhone.getText().toString().trim();
        String dob       = etDob.getText().toString().trim();
        String gender    = spnGender.getSelectedItemPosition() > 0
                           ? spnGender.getSelectedItem().toString() : null;
        String blood     = spnBlood.getSelectedItemPosition() > 0
                           ? spnBlood.getSelectedItem().toString() : null;

        tvError.setVisibility(View.GONE);

        if (TextUtils.isEmpty(firstName) || TextUtils.isEmpty(lastName)) {
            showError("First and last name are required");
            return;
        }
        if (TextUtils.isEmpty(email) || !email.contains("@")) {
            showError("Valid email is required");
            return;
        }
        if (TextUtils.isEmpty(password) || password.length() < 6) {
            showError("Password must be at least 6 characters");
            return;
        }
        if (!password.equals(confirm)) {
            showError("Passwords do not match");
            return;
        }

        btnCreate.setEnabled(false);

        Map<String, String> body = new HashMap<>();
        body.put("first_name", firstName);
        body.put("last_name",  lastName);
        body.put("email",      email);
        body.put("password",   password);
        if (!phone.isEmpty())  body.put("phone", phone);
        if (!dob.isEmpty())    body.put("date_of_birth", dob);
        if (gender != null)    body.put("gender", gender);
        if (blood != null)     body.put("blood_type", blood);

        ApiClient.getService().register(body).enqueue(new Callback<ApiService.ApiResponse<ApiService.LoginData>>() {
            @Override
            public void onResponse(Call<ApiService.ApiResponse<ApiService.LoginData>> call,
                                   Response<ApiService.ApiResponse<ApiService.LoginData>> response) {
                btnCreate.setEnabled(true);

                if (response.isSuccessful() && response.body() != null && response.body().success) {
                    ApiService.LoginData data = response.body().data;

                    SharedPreferences prefs = getSharedPreferences("hmss_prefs", MODE_PRIVATE);
                    prefs.edit()
                        .putString("access_token",  data.access_token)
                        .putString("refresh_token", data.refresh_token)
                        .putString("user_json",     new Gson().toJson(data.user))
                        .apply();

                    ApiClient.setAccessToken(data.access_token);

                    // Fetch patient_id before navigating so all screens work correctly.
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
                                Intent intent = new Intent(SignUpActivity.this, PatientDashboardActivity.class);
                                intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                                startActivity(intent);
                            }
                            @Override
                            public void onFailure(
                                    retrofit2.Call<ApiService.ApiResponse<ApiService.PatientProfile>> call,
                                    Throwable t) {
                                Intent intent = new Intent(SignUpActivity.this, PatientDashboardActivity.class);
                                intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                                startActivity(intent);
                            }
                        }
                    );
                } else {
                    String msg = (response.body() != null && response.body().message != null)
                        ? response.body().message : "Registration failed";
                    showError(msg);
                }
            }

            @Override
            public void onFailure(Call<ApiService.ApiResponse<ApiService.LoginData>> call, Throwable t) {
                btnCreate.setEnabled(true);
                showError("Cannot reach server: " + t.getMessage() + "\nMake sure the backend is running.");
            }
        });
    }

    private void showError(String msg) {
        tvError.setText(msg);
        tvError.setVisibility(View.VISIBLE);
    }
}
