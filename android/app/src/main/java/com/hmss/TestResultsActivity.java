package com.hmss;

import android.content.SharedPreferences;
import android.graphics.Color;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;

import com.google.gson.Gson;
import com.hmss.models.TestResult;
import com.hmss.models.User;
import com.hmss.network.ApiClient;
import com.hmss.network.ApiService;

import java.util.ArrayList;
import java.util.List;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

/**
 * TestResultsActivity — List of the patient's test results.
 *
 * - Results sorted newest-first by the API.
 * - Abnormal (flagged) results are highlighted in red.
 * - Tap a result to see its full detail dialog.
 */
public class TestResultsActivity extends AppCompatActivity {

    private List<TestResult>   resultList = new ArrayList<>();
    private TestResultAdapter  adapter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_test_results);

        ListView lv = findViewById(R.id.lv_results);
        adapter = new TestResultAdapter(resultList);
        lv.setAdapter(adapter);

        lv.setOnItemClickListener((parent, view, position, id) -> showDetail(resultList.get(position)));

        loadResults();
    }

    /** Fetch test results from the API. */
    private void loadResults() {
        ApiClient.getService().getTestResults().enqueue(new Callback<ApiService.ApiResponse<List<TestResult>>>() {
            @Override
            public void onResponse(Call<ApiService.ApiResponse<List<TestResult>>> call,
                                   Response<ApiService.ApiResponse<List<TestResult>>> response) {
                if (response.isSuccessful() && response.body() != null && response.body().success) {
                    resultList.clear();
                    resultList.addAll(response.body().data);
                    adapter.notifyDataSetChanged();
                }
            }

            @Override
            public void onFailure(Call<ApiService.ApiResponse<List<TestResult>>> call, Throwable t) {
                Toast.makeText(TestResultsActivity.this, "Failed to load results", Toast.LENGTH_SHORT).show();
            }
        });
    }

    /**
     * Show a dialog with full result details:
     * test name, value, unit, normal range, flagged status.
     */
    private void showDetail(TestResult r) {
        StringBuilder sb = new StringBuilder();
        sb.append("Test:   ").append(r.testName != null ? r.testName : r.testCode).append("\n");
        sb.append("Date:   ").append(r.resultDate != null ? r.resultDate : "—").append("\n");
        sb.append("Value:  ").append(r.value).append(" ").append(r.unit != null ? r.unit : "").append("\n");
        sb.append("Status: ").append(r.status).append("\n");

        if (r.normalRange != null) {
            sb.append("Normal: ").append(r.normalRange.getDisplayRange()).append("\n");
        }

        if (r.isFlagged) {
            sb.append("\n⚠️ This result is ABNORMAL. Please consult your doctor.");
        }
        if (r.notes != null && !r.notes.isEmpty()) {
            sb.append("\nNotes:  ").append(r.notes);
        }

        new AlertDialog.Builder(this)
            .setTitle(r.isFlagged ? "⚠️ Flagged Result" : "Test Result Detail")
            .setMessage(sb.toString())
            .setPositiveButton("Close", null)
            .show();
    }

    /** Adapter that highlights flagged rows in red. */
    private class TestResultAdapter extends ArrayAdapter<TestResult> {
        TestResultAdapter(List<TestResult> items) {
            super(TestResultsActivity.this, android.R.layout.simple_list_item_2, items);
        }

        @Override
        public View getView(int position, View convertView, ViewGroup parent) {
            if (convertView == null) {
                convertView = LayoutInflater.from(getContext()).inflate(android.R.layout.simple_list_item_2, parent, false);
            }

            TestResult r = getItem(position);
            TextView text1 = convertView.findViewById(android.R.id.text1);
            TextView text2 = convertView.findViewById(android.R.id.text2);

            String name = r.testName != null ? r.testName : ("Test #" + r.testId);
            text1.setText((r.isFlagged ? "⚠️ " : "") + name + " — " + r.value + " " + (r.unit != null ? r.unit : ""));
            text2.setText(r.resultDate + " | " + r.status);

            // Highlight abnormal rows
            convertView.setBackgroundColor(r.isFlagged
                ? Color.parseColor("#FFEBEE")   // light red
                : Color.WHITE);

            return convertView;
        }
    }
}
