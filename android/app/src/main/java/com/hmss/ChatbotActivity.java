package com.hmss;

import android.graphics.Color;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.hmss.network.ApiClient;
import com.hmss.network.ApiService;

import java.util.HashMap;
import java.util.Map;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

/**
 * ChatbotActivity — Simple chat UI for the restricted medical chatbot.
 *
 * Layout:
 *   - Disclaimer banner at the top.
 *   - Scrollable message list (user messages right, bot left).
 *   - Text input + Send button at the bottom.
 *
 * All messages sent to POST /api/chatbot/query.
 * The chatbot provides reference information ONLY — no diagnosis or advice.
 */
public class ChatbotActivity extends AppCompatActivity {

    private LinearLayout chatContainer;
    private ScrollView   scrollView;
    private EditText     etInput;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_chatbot);

        chatContainer = findViewById(R.id.chat_container);
        scrollView    = findViewById(R.id.scroll_view);
        etInput       = findViewById(R.id.et_message);

        Button btnSend = findViewById(R.id.btn_send);
        if (btnSend != null) btnSend.setOnClickListener(v -> sendMessage());

        // Show a disclaimer bubble as the first bot message
        addBotMessage(
            "⚠️ This chatbot provides reference information only. " +
            "It does NOT provide medical diagnoses or advice. " +
            "Always consult a qualified healthcare professional."
        );

        // Greet the user
        addBotMessage("Hello! I can help you with:\n• How to use the HMSS app\n• Normal ranges for medical tests\n\nWhat would you like to know?");
    }

    /** Read the input, add user bubble, call API, display response. */
    private void sendMessage() {
        if (etInput == null) return;
        String text = etInput.getText().toString().trim();
        if (text.isEmpty()) return;

        addUserMessage(text);
        etInput.setText("");

        Map<String, String> body = new HashMap<>();
        body.put("query", text);

        ApiClient.getService().chatbotQuery(body).enqueue(new Callback<ApiService.ApiResponse<ApiService.ChatbotResponse>>() {
            @Override
            public void onResponse(Call<ApiService.ApiResponse<ApiService.ChatbotResponse>> call,
                                   Response<ApiService.ApiResponse<ApiService.ChatbotResponse>> response) {
                if (response.isSuccessful() && response.body() != null && response.body().success) {
                    String reply = response.body().data != null
                        ? response.body().data.response_text
                        : "I'm sorry, I couldn't process your question.";
                    addBotMessage(reply);
                } else {
                    addBotMessage("Sorry, I encountered an error. Please try again.");
                }
            }

            @Override
            public void onFailure(Call<ApiService.ApiResponse<ApiService.ChatbotResponse>> call, Throwable t) {
                addBotMessage("Network error. Please check your connection.");
            }
        });
    }

    /** Add a right-aligned user message bubble. */
    private void addUserMessage(String text) {
        TextView tv = createBubble(text, true);
        chatContainer.addView(tv);
        scrollToBottom();
    }

    /** Add a left-aligned bot message bubble. */
    private void addBotMessage(String text) {
        TextView tv = createBubble(text, false);
        chatContainer.addView(tv);
        scrollToBottom();
    }

    /**
     * Create a styled message bubble TextView.
     * @param text    Message content.
     * @param isUser  True for user (right-aligned, blue), false for bot (left, grey).
     */
    private TextView createBubble(String text, boolean isUser) {
        TextView tv = new TextView(this);
        tv.setText(text);
        tv.setTextSize(15);
        tv.setPadding(24, 16, 24, 16);

        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
            (int) (getResources().getDisplayMetrics().widthPixels * 0.75),
            LinearLayout.LayoutParams.WRAP_CONTENT
        );
        params.setMargins(8, 8, 8, 8);

        if (isUser) {
            tv.setBackgroundColor(Color.parseColor("#1a73e8"));
            tv.setTextColor(Color.WHITE);
            params.gravity = Gravity.END;
        } else {
            tv.setBackgroundColor(Color.parseColor("#F1F3F4"));
            tv.setTextColor(Color.parseColor("#202124"));
            params.gravity = Gravity.START;
        }

        tv.setLayoutParams(params);
        return tv;
    }

    /** Scroll the chat view to the latest message. */
    private void scrollToBottom() {
        if (scrollView != null) {
            scrollView.post(() -> scrollView.fullScroll(ScrollView.FOCUS_DOWN));
        }
    }
}
