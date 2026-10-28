/**
 * auth.js — Login form handling
 */

function showToast(message, type) {
  var container = document.getElementById("toast-container");
  if (!container) {
    container = document.createElement("div");
    container.id = "toast-container";
    document.body.appendChild(container);
  }
  var toast = document.createElement("div");
  toast.className = "toast toast-" + (type || "info");
  toast.textContent = message;
  container.appendChild(toast);
  setTimeout(function() { toast.remove(); }, 4000);
}

document.addEventListener("DOMContentLoaded", function() {
  var form = document.getElementById("login-form");
  if (!form) return;

  form.addEventListener("submit", async function(e) {
    e.preventDefault();
    var email = document.getElementById("email").value.trim();
    var password = document.getElementById("password").value;
    var errorMsg = document.getElementById("error-msg");
    errorMsg.style.display = "none";

    var data = await api.post("/api/auth/login", { email: email, password: password });

    if (!data.success) {
      errorMsg.textContent = data.message || "Login failed";
      errorMsg.style.display = "block";
      return;
    }

    localStorage.setItem("access_token", data.data.access_token);
    localStorage.setItem("refresh_token", data.data.refresh_token);
    localStorage.setItem("user", JSON.stringify(data.data.user));

    var role = data.data.user.role;
    if (role === "doctor") {
      window.location.href = "/doctor/dashboard.html";
    } else if (role === "secretary") {
      window.location.href = "/secretary/dashboard.html";
    } else {
      errorMsg.textContent = "Web dashboard is for doctors and secretaries only.";
      errorMsg.style.display = "block";
      clearSession();
    }
  });
});

// Logout function - used by all pages
function logout() {
  var token = localStorage.getItem("access_token");
  if (token) {
    fetch("/api/auth/logout", {
      method: "POST",
      headers: {
        "Authorization": "Bearer " + token,
        "Content-Type": "application/json"
      }
    });
  }
  localStorage.clear();
  window.location.href = "/index.html";
}