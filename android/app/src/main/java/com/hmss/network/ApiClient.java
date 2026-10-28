package com.hmss.network;

import com.hmss.BuildConfig;
import java.util.concurrent.TimeUnit;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

/**
 * ApiClient — Singleton Retrofit instance.
 *
 * BASE_URL is set per build type in app/build.gradle:
 *   debug   → LAN IP for physical device (http://192.168.x.x:5000/)
 *             or 10.0.2.2:5000 for the Android emulator
 *   release → production HTTPS URL
 */
public class ApiClient {

    /** Base URL injected from build config — do not hardcode here. */
    private static final String BASE_URL = BuildConfig.BASE_URL;

    private static Retrofit retrofit = null;

    /** Shared preferences key where the JWT token is stored. */
    public static String accessToken = null;

    /**
     * Build (once) and return the Retrofit instance.
     * Subsequent calls return the same cached instance.
     */
    public static Retrofit getClient() {
        if (retrofit == null) {
            // OkHttp client that injects the Authorization header on every request
            OkHttpClient httpClient = new OkHttpClient.Builder()
                .connectTimeout(10, TimeUnit.SECONDS)
                .readTimeout(10, TimeUnit.SECONDS)
                .addInterceptor(chain -> {
                    Request original = chain.request();
                    Request.Builder builder = original.newBuilder()
                        .header("Content-Type", "application/json");

                    if (accessToken != null && !accessToken.isEmpty()) {
                        builder.header("Authorization", "Bearer " + accessToken);
                    }

                    return chain.proceed(builder.build());
                })
                .build();

            retrofit = new Retrofit.Builder()
                .baseUrl(BASE_URL)
                .client(httpClient)
                .addConverterFactory(GsonConverterFactory.create())
                .build();
        }
        return retrofit;
    }

    /**
     * Return the ApiService interface, ready for use.
     */
    public static ApiService getService() {
        return getClient().create(ApiService.class);
    }

    /**
     * Update the stored access token (called after login / token refresh).
     * @param token New JWT access token string.
     */
    public static void setAccessToken(String token) {
        accessToken = token;
    }

    /**
     * Clear the access token (called on logout).
     */
    public static void clearToken() {
        accessToken = null;
    }
}
