package com.hmss;

import android.content.SharedPreferences;
import android.graphics.Color;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.TabHost;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;

import com.hmss.models.Appointment;
import com.hmss.network.ApiClient;
import com.hmss.network.ApiService;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

/**
 * AppointmentsActivity — Shows upcoming and past appointments.
 *
 * Two tabs:
 *   - Upcoming: pending, confirmed, rescheduled appointments.
 *   - Past:     completed, cancelled appointments.
 *
 * Also provides a button to request a new appointment.
 */
public class AppointmentsActivity extends AppCompatActivity {

    private List<Appointment> upcomingList = new ArrayList<>();
    private List<Appointment> pastList     = new ArrayList<>();
    private AppointmentAdapter upcomingAdapter, pastAdapter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_appointments);

        // Setup tab host
        TabHost tabHost = findViewById(R.id.tab_host);
        tabHost.setup();

        TabHost.TabSpec tab1 = tabHost.newTabSpec("upcoming");
        tab1.setContent(R.id.tab_upcoming);
        tab1.setIndicator("Upcoming");
        tabHost.addTab(tab1);

        TabHost.TabSpec tab2 = tabHost.newTabSpec("past");
        tab2.setContent(R.id.tab_past);
        tab2.setIndicator("Past");
        tabHost.addTab(tab2);

        // List adapters
        ListView lvUpcoming = findViewById(R.id.lv_upcoming);
        ListView lvPast     = findViewById(R.id.lv_past);

        upcomingAdapter = new AppointmentAdapter(upcomingList);
        pastAdapter     = new AppointmentAdapter(pastList);
        lvUpcoming.setAdapter(upcomingAdapter);
        lvPast.setAdapter(pastAdapter);

        // New appointment button
        Button btnNew = findViewById(R.id.btn_new_appointment);
        if (btnNew != null) btnNew.setOnClickListener(v -> showNewAppointmentDialog());

        loadAppointments();
    }

    /** Fetch appointments from the API and split into upcoming / past. */
    private void loadAppointments() {
        ApiClient.getService().getAppointments().enqueue(new Callback<ApiService.ApiResponse<List<Appointment>>>() {
            @Override
            public void onResponse(Call<ApiService.ApiResponse<List<Appointment>>> call,
                                   Response<ApiService.ApiResponse<List<Appointment>>> response) {
                if (response.isSuccessful() && response.body() != null && response.body().success) {
                    upcomingList.clear();
                    pastList.clear();

                    for (Appointment a : response.body().data) {
                        if ("completed".equals(a.status) || "cancelled".equals(a.status)) {
                            pastList.add(a);
                        } else {
                            upcomingList.add(a);
                        }
                    }

                    upcomingAdapter.notifyDataSetChanged();
                    pastAdapter.notifyDataSetChanged();
                }
            }

            @Override
            public void onFailure(Call<ApiService.ApiResponse<List<Appointment>>> call, Throwable t) {
                Toast.makeText(AppointmentsActivity.this, "Failed to load appointments", Toast.LENGTH_SHORT).show();
            }
        });
    }

    /** Show a simple dialog to request a new appointment. */
    private void showNewAppointmentDialog() {
        SharedPreferences prefs = getSharedPreferences("hmss_prefs", MODE_PRIVATE);
        int patientId = prefs.getInt("patient_id", -1);
        if (patientId == -1) {
            Toast.makeText(this, "Patient profile not found. Please log out and log in again.", Toast.LENGTH_LONG).show();
            return;
        }

        View view = LayoutInflater.from(this).inflate(android.R.layout.simple_list_item_2, null);
        EditText etDoctorId  = new EditText(this); etDoctorId.setHint("Doctor ID");
        EditText etStart     = new EditText(this); etStart.setHint("Start (YYYY-MM-DDTHH:MM)");
        EditText etEnd       = new EditText(this); etEnd.setHint("End   (YYYY-MM-DDTHH:MM)");
        EditText etReason    = new EditText(this); etReason.setHint("Reason (optional)");

        ViewGroup layout = new android.widget.LinearLayout(this);
        ((android.widget.LinearLayout) layout).setOrientation(android.widget.LinearLayout.VERTICAL);
        layout.setPadding(40, 20, 40, 0);
        layout.addView(etDoctorId);
        layout.addView(etStart);
        layout.addView(etEnd);
        layout.addView(etReason);

        new AlertDialog.Builder(this)
            .setTitle("Request New Appointment")
            .setView(layout)
            .setPositiveButton("Submit", (dialog, which) -> {
                String doctorIdStr = etDoctorId.getText().toString().trim();
                String start       = etStart.getText().toString().trim();
                String end         = etEnd.getText().toString().trim();
                String reason      = etReason.getText().toString().trim();

                if (doctorIdStr.isEmpty() || start.isEmpty() || end.isEmpty()) {
                    Toast.makeText(this, "Doctor ID, start, and end are required", Toast.LENGTH_SHORT).show();
                    return;
                }

                Map<String, Object> body = new HashMap<>();
                body.put("patient_id",      patientId);
                body.put("doctor_id",       Integer.parseInt(doctorIdStr));
                body.put("scheduled_start", start);
                body.put("scheduled_end",   end);
                if (!reason.isEmpty()) body.put("reason", reason);

                ApiClient.getService().createAppointment(body).enqueue(new Callback<ApiService.ApiResponse<Appointment>>() {
                    @Override
                    public void onResponse(Call<ApiService.ApiResponse<Appointment>> call,
                                           Response<ApiService.ApiResponse<Appointment>> response) {
                        String msg = (response.body() != null) ? response.body().message : "Request sent";
                        Toast.makeText(AppointmentsActivity.this, msg, Toast.LENGTH_SHORT).show();
                        if (response.body() != null && response.body().success) loadAppointments();
                    }
                    @Override
                    public void onFailure(Call<ApiService.ApiResponse<Appointment>> call, Throwable t) {
                        Toast.makeText(AppointmentsActivity.this, "Network error", Toast.LENGTH_SHORT).show();
                    }
                });
            })
            .setNegativeButton("Cancel", null)
            .show();
    }

    /** Simple adapter that renders an Appointment row with status colour. */
    private class AppointmentAdapter extends ArrayAdapter<Appointment> {
        AppointmentAdapter(List<Appointment> items) {
            super(AppointmentsActivity.this, android.R.layout.simple_list_item_2, items);
        }

        @Override
        public View getView(int position, View convertView, ViewGroup parent) {
            if (convertView == null) {
                convertView = LayoutInflater.from(getContext()).inflate(android.R.layout.simple_list_item_2, parent, false);
            }

            Appointment a = getItem(position);
            TextView text1 = convertView.findViewById(android.R.id.text1);
            TextView text2 = convertView.findViewById(android.R.id.text2);

            text1.setText((a.doctorName != null ? "Dr. " + a.doctorName : "Doctor #" + a.doctorId)
                + " — " + a.getDisplayStart());

            text2.setText("Status: " + a.status + (a.reason != null ? " | " + a.reason : ""));

            // Colour the row by status
            int bg = Color.WHITE;
            switch (a.status != null ? a.status : "") {
                case "confirmed":   bg = Color.parseColor("#E6F4EA"); break;
                case "rescheduled": bg = Color.parseColor("#FFF8E1"); break;
                case "cancelled":   bg = Color.parseColor("#FCE8E6"); break;
                case "pending":     bg = Color.parseColor("#F1F3F4"); break;
            }
            convertView.setBackgroundColor(bg);
            return convertView;
        }
    }
}
