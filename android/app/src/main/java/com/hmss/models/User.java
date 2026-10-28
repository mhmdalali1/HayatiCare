package com.hmss.models;

import com.google.gson.annotations.SerializedName;

/**
 * User — represents the base user account returned by the API.
 */
public class User {

    @SerializedName("user_id")   public int    userId;
    @SerializedName("role")      public String role;
    @SerializedName("first_name")public String firstName;
    @SerializedName("last_name") public String lastName;
    @SerializedName("email")     public String email;
    @SerializedName("phone")     public String phone;
    @SerializedName("is_active") public boolean isActive;

    /** Convenience: full display name. */
    public String getFullName() {
        return (firstName != null ? firstName : "") + " " + (lastName != null ? lastName : "");
    }
}
