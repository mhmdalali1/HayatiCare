package com.hmss.models;

import com.google.gson.annotations.SerializedName;

/**
 * Notification — an in-app notification for a user.
 */
public class Notification {

    @SerializedName("notification_id") public int     notificationId;
    @SerializedName("user_id")         public int     userId;
    @SerializedName("type")            public String  type;
    @SerializedName("title")           public String  title;
    @SerializedName("message")         public String  message;
    @SerializedName("is_read")         public boolean isRead;
    @SerializedName("created_at")      public String  createdAt;
    @SerializedName("read_at")         public String  readAt;
}
