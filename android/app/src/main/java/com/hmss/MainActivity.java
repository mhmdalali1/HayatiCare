package com.hmss;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;

/**
 * MainActivity — Entry point / splash screen.
 *
 * Checks for a stored JWT token:
 *   - If present → go directly to PatientDashboardActivity.
 *   - If absent  → go to LoginActivity.
 */
public class MainActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        SharedPreferences prefs = getSharedPreferences("hmss_prefs", MODE_PRIVATE);
        String token = prefs.getString("access_token", null);

        Intent next;
        if (token != null && !token.isEmpty()) {
            // Restore token into Retrofit client
            com.hmss.network.ApiClient.setAccessToken(token);
            next = new Intent(this, PatientDashboardActivity.class);
        } else {
            next = new Intent(this, LoginActivity.class);
        }

        startActivity(next);
        finish(); // Remove MainActivity from back stack
    }
}
