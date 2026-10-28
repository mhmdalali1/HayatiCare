/**
 * api.js — Fetch wrapper with automatic JWT header injection.
 */

var BASE_URL = "";

async function apiFetch(endpoint, options) {
  options = options || {};
  var token = localStorage.getItem("access_token");

  console.log("apiFetch:", options.method || "GET", BASE_URL + endpoint);

  var headers = {
    "Content-Type": "application/json",
    "Cache-Control": "no-cache",
    "Pragma": "no-cache"
  };

  if (token) {
    headers["Authorization"] = "Bearer " + token;
  }

  if (options.headers) {
    for (var key in options.headers) {
      headers[key] = options.headers[key];
    }
  }

  var response = await fetch(BASE_URL + endpoint, {
    method: options.method || "GET",
    headers: headers,
    body: options.body
  });

  var contentType = response.headers.get("content-type");
  var isJson = contentType && contentType.includes("application/json");

  if (response.status === 401) {
    var refreshed = await tryRefreshToken();
    if (!refreshed) {
      clearSession();
      window.location.href = "/index.html";
      return;
    }
    return apiFetch(endpoint, options);
  }

  if (!response.ok) {
    if (isJson) {
      return response.json();
    } else {
      var text = await response.text();
      console.error("API Error:", response.status, text);
      return { success: false, message: "Request failed: " + response.status };
    }
  }

  if (isJson) {
    return response.json();
  } else {
    return { success: true, data: null };
  }
}

async function tryRefreshToken() {
  var refreshToken = localStorage.getItem("refresh_token");
  if (!refreshToken) return false;

  try {
    var res = await fetch(BASE_URL + "/api/auth/refresh", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer " + refreshToken
      }
    });
    var data = await res.json();
    if (data.success && data.data && data.data.access_token) {
      localStorage.setItem("access_token", data.data.access_token);
      return true;
    }
  } catch (e) {}
  return false;
}

function clearSession() {
  localStorage.removeItem("access_token");
  localStorage.removeItem("refresh_token");
  localStorage.removeItem("user");
}

function requireAuth() {
  if (!localStorage.getItem("access_token")) {
    window.location.href = "/index.html";
  }
}

function getCurrentUser() {
  try {
    return JSON.parse(localStorage.getItem("user"));
  } catch (e) {
    return null;
  }
}

var api = {
  get: function(endpoint) {
    return apiFetch(endpoint, { method: "GET" });
  },
  post: function(endpoint, body) {
    return apiFetch(endpoint, { method: "POST", body: JSON.stringify(body) });
  },
  put: function(endpoint, body) {
    return apiFetch(endpoint, { method: "PUT", body: JSON.stringify(body) });
  },
  delete: function(endpoint) {
    return apiFetch(endpoint, { method: "DELETE" });
  }
};