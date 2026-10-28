package com.hmss;

import android.content.SharedPreferences;
import android.os.Bundle;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Spinner;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.hmss.models.TestResult;
import com.hmss.network.ApiClient;
import com.hmss.network.ApiService;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

/**
 * HomeTestSubmitActivity — Form for patients to submit home measurements.
 *
 * Fields:
 *   - Test type selector (populated from API)
 *   - Value input
 *   - Unit
 *   - Date
 *   - Fasting state
 *
 * Submits to POST /api/patients/<id>/home-tests.
 */
public class HomeTestSubmitActivity extends AppCompatActivity {

    private EditText etTestId, etDoctorId, etValue, etUnit, etDate, etNotes;
    private Spinner  spnFasting;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_home_test_submit);

        etTestId   = findViewById(R.id.et_test_id);
        etDoctorId = findViewById(R.id.et_doctor_id);
        etValue    = findViewById(R.id.et_value);
        etUnit     = findViewById(R.id.et_unit);
        etDate     = findViewById(R.id.et_date);
        etNotes    = findViewById(R.id.et_notes);
        spnFasting = findViewById(R.id.spn_fasting);

        // Populate fasting state spinner
        ArrayAdapter<String> fastingAdapter = new ArrayAdapter<>(
            this, android.R.layout.simple_spinner_item,
            Arrays.asList("unknown", "fasting", "non-fasting")
        );
        fastingAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        if (spnFasting != null) spnFasting.setAdapter(fastingAdapter);

        Button btnSubmit = findViewById(R.id.btn_submit_home_test);
        if (btnSubmit != null) btnSubmit.setOnClickListener(v -> submitHomeTest());
    }

    /** Validate and submit the home test measurement. */
    private void submitHomeTest() {
        String testIdStr   = etTestId  != null ? etTestId.getText().toString().trim()   : "";
        String doctorIdStr = etDoctorId!= null ? etDoctorId.getText().toString().trim() : "";
        String valueStr    = etValue   != null ? etValue.getText().toString().trim()    : "";
        String unit        = etUnit    != null ? etUnit.getText().toString().trim()     : "";
        String date        = etDate    != null ? etDate.getText().toString().trim()     : "";
        String notes       = etNotes   != null ? etNotes.getText().toString().trim()    : "";
        String fasting     = spnFasting != null ? spnFasting.getSelectedItem().toString() : "unknown";

        if (testIdStr.isEmpty() || doctorIdStr.isEmpty() || valueStr.isEmpty() || date.isEmpty()) {
            Toast.makeText(this, "Test ID, doctor ID, value and date are required", Toast.LENGTH_SHORT).show();
            return;
        }

        SharedPreferences prefs = getSharedPreferences("hmss_prefs", MODE_PRIVATE);
        int patientId = prefs.getInt("patient_id", -1);
        if (patientId == -1) {
            Toast.makeText(this, "Patient profile not found. Please log out and log in again.", Toast.LENGTH_LONG).show();
            return;
        }

        Map<String, Object> body = new HashMap<>();
        body.put("test_id",       Integer.parseInt(testIdStr));
        body.put("doctor_id",     Integer.parseInt(doctorIdStr));
        body.put("value",         Double.parseDouble(valueStr));
        body.put("unit",          unit);
        body.put("result_date",   date);
        body.put("fasting_state", "unknown".equals(fasting) ? null : fasting);
        if (!notes.isEmpty()) body.put("notes", notes);

        ApiClient.getService().submitHomeTest(patientId, body)
            .enqueue(new Callback<ApiService.ApiResponse<TestResult>>() {
                @Override
                public void onResponse(Call<ApiService.ApiResponse<TestResult>> call,
                                       Response<ApiService.ApiResponse<TestResult>> response) {
                    String msg = (response.body() != null) ? response.body().message : "Submitted";
                    Toast.makeText(HomeTestSubmitActivity.this, msg, Toast.LENGTH_SHORT).show();
                    if (response.body() != null && response.body().success) {
                        // Clear fields
                        if (etValue != null) etValue.setText("");
                        if (etNotes != null) etNotes.setText("");
                    }
                }
                @Override
                public void onFailure(Call<ApiService.ApiResponse<TestResult>> call, Throwable t) {
                    Toast.makeText(HomeTestSubmitActivity.this, "Network error", Toast.LENGTH_SHORT).show();
                }
            });
    }
}
