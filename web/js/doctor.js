/**
 * doctor.js — Doctor dashboard & SPA navigation
 */

var _dashboardRefreshInterval = null;

function initSidebar(user) {
  var nameEl = document.getElementById("sidebar-user-name");
  if (nameEl && user) {
    nameEl.textContent = "Dr. " + user.first_name + " " + user.last_name;
  }
}

function startAutoRefresh() {
  stopAutoRefresh();
  _dashboardRefreshInterval = setInterval(function() {
    loadDashboard();
  }, 5000);
}

function stopAutoRefresh() {
  if (_dashboardRefreshInterval) {
    clearInterval(_dashboardRefreshInterval);
    _dashboardRefreshInterval = null;
  }
}

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

function fmtDate(iso) {
  if (!iso) return "—";
  return new Date(iso).toLocaleString();
}

function statusBadge(status) {
  return "<span class=\"badge badge-" + status + "\">" + status + "</span>";
}

function logout() {
  var token = localStorage.getItem("access_token");
  if (token) {
    fetch("/api/auth/logout", {
      method: "POST",
      headers: { "Authorization": "Bearer " + token, "Content-Type": "application/json" }
    });
  }
  localStorage.clear();
  window.location.href = "/index.html";
}

// ===== Dashboard =====
function loadDashboard() {
  api.get("/api/appointments").then(function(data) {
    if (!data.success) return;
    var today = new Date().toDateString();
    var appts = (data.data || []).filter(function(a) {
      return new Date(a.scheduled_start).toDateString() === today;
    });

    var el = document.getElementById("stat-today-appts");
    if (el) el.textContent = appts.length;

    var tbody = document.getElementById("dashboard-appts-tbody");
    if (!tbody) return;
    tbody.innerHTML = "";
    if (appts.length === 0) {
      tbody.innerHTML = '<tr><td colspan="5" class="text-muted" style="padding:24px;text-align:center;">No appointments today</td></tr>';
      return;
    }
    appts.forEach(function(a) {
      var tr = document.createElement("tr");
      tr.innerHTML =
        "<td>" + (a.patient_name || "?") + "</td>" +
        "<td>" + fmtDate(a.scheduled_start) + "</td>" +
        "<td>" + fmtDate(a.scheduled_end) + "</td>" +
        "<td>" + (a.reason || "—") + "</td>" +
        "<td>" + statusBadge(a.status) + "</td>";
      tbody.appendChild(tr);
    });
  });

  api.get("/api/patient-results").then(function(data) {
    var el = document.getElementById("stat-flagged");
    if (el && data.success) {
      var flagged = (data.data || []).filter(function(r) { return r.status === "high" || r.status === "low"; });
      el.textContent = flagged.length;
    }
  });
}

// ===== Appointments =====
function loadAppointments() {
  var tbody = document.getElementById("appt-tbody");
  if (!tbody) return;
  tbody.innerHTML = "<tr><td colspan='7'>Loading...</td></tr>";

  api.get("/api/appointments").then(function(data) {
    if (!data.success) {
      tbody.innerHTML = "<tr><td colspan='7'>Error: " + data.message + "</td></tr>";
      return;
    }
    tbody.innerHTML = "";
    var list = data.data || [];
    if (list.length === 0) {
      tbody.innerHTML = '<tr><td colspan="7" class="text-muted">No appointments</td></tr>';
      return;
    }
    list.forEach(function(a) {
      var tr = document.createElement("tr");
      tr.innerHTML =
        "<td>" + (a.patient_name || "?") + "</td>" +
        "<td>" + fmtDate(a.scheduled_start) + "</td>" +
        "<td>" + fmtDate(a.scheduled_end) + "</td>" +
        "<td>" + (a.reason || "?") + "</td>" +
        "<td>" + (a.location || "?") + "</td>" +
        "<td>" + statusBadge(a.status) + "</td>" +
        "<td>" +
          (a.status === "pending" ? "<button class=\"btn btn-sm btn-success\" onclick=\"confirmAppt(" + a.appointment_id + ")\">Confirm</button> " : "") +
          "<button class=\"btn btn-sm btn-danger\" onclick=\"cancelAppt(" + a.appointment_id + ")\">Cancel</button>" +
        "</td>";
      tbody.appendChild(tr);
    });
  });
}

function confirmAppt(id) {
  api.put("/api/appointments/" + id, { status: "confirmed" }).then(function(data) {
    showToast(data.message, data.success ? "success" : "error");
    if (data.success) loadAppointments();
  });
}

function cancelAppt(id) {
  if (!confirm("Cancel this appointment?")) return;
  api.put("/api/appointments/" + id, { status: "cancelled" }).then(function(data) {
    showToast(data.message, data.success ? "success" : "error");
    if (data.success) loadAppointments();
  });
}

// ===== Patient Records =====
function loadPatientRecords() {
  var tbody = document.getElementById("patients-tbody");
  if (!tbody) return;
  tbody.innerHTML = "<tr><td colspan='7'>Loading...</td></tr>";

  api.get("/api/patients/my-patients").then(function(data) {
    if (!data.success) {
      tbody.innerHTML = "<tr><td colspan='7'>Error: " + data.message + "</td></tr>";
      return;
    }
    tbody.innerHTML = "";
    var list = data.data || [];
    if (list.length === 0) {
      tbody.innerHTML = '<tr><td colspan="7" class="text-muted">No patients with appointments</td></tr>';
      return;
    }
    list.forEach(function(p) {
      var tr = document.createElement("tr");
      tr.innerHTML =
        "<td>" + (p.patient_code || "—") + "</td>" +
        "<td>" + (p.first_name || "") + " " + (p.last_name || "") + "</td>" +
        "<td>" + (p.email || "—") + "</td>" +
        "<td>" + (p.phone || "—") + "</td>" +
        "<td>" + (p.date_of_birth || "—") + "</td>" +
        "<td>" + (p.gender || "—") + "</td>" +
        "<td>" + (p.blood_type || "—") + "</td>";
      tbody.appendChild(tr);
    });
  });
}

// ===== SPA Navigation =====
(function() {
  var spaState = { currentPage: "", isLoading: false };

  function initSPA() {
    document.querySelectorAll(".sidebar-nav a").forEach(function(link) {
      link.addEventListener("click", function(e) {
        e.preventDefault();
        var href = link.getAttribute("href");
        if (href && href !== spaState.currentPage) {
          navigateTo(href);
        }
      });
    });

    window.addEventListener("popstate", function(e) {
      if (e.state && e.state.page) {
        loadContent(e.state.page, true);
      }
    });

    var initial = window.location.pathname.split("/").pop() || "dashboard.html";
    spaState.currentPage = initial;

    var user = getCurrentUser();
    if (!user || user.role !== "doctor") {
      clearSession();
      window.location.href = "/index.html";
      return;
    }
    initSidebar(user);
  }

  window.navigateTo = navigateTo;

  function navigateTo(url) {
    history.pushState({ page: url }, "", url);
    loadContent(url, false);
  }

  function loadContent(url, isPopState) {
    if (spaState.isLoading) return;
    spaState.isLoading = true;

    var mainEl = document.getElementById("main-content");
    if (!mainEl) { spaState.isLoading = false; return; }

    if (typeof pageDestroy === "function") pageDestroy();
    stopAutoRefresh();

    mainEl.classList.add("content-loading");
    mainEl.innerHTML = buildSkeleton();

    fetch(url)
      .then(function(r) {
        if (!r.ok) throw new Error("Page not found (" + r.status + ")");
        return r.text();
      })
      .then(function(html) {
        var doc = new DOMParser().parseFromString(html, "text/html");
        var newMain = doc.getElementById("main-content");
        if (!newMain) throw new Error("Main content not found");

        var title = doc.querySelector("title");
        if (title) document.title = title.textContent;

        mainEl.classList.remove("content-loading");
        mainEl.classList.add("content-exit");
        setTimeout(function() {
          mainEl.innerHTML = newMain.innerHTML;
          mainEl.classList.remove("content-exit");
          mainEl.classList.add("content-enter");

          runPageScripts(mainEl);

          updateActiveSidebar(url);
          spaState.currentPage = url;

          setTimeout(function() {
            mainEl.classList.remove("content-enter");
          }, 350);
          spaState.isLoading = false;
        }, 120);
      })
      .catch(function(err) {
        mainEl.classList.remove("content-loading");
        mainEl.innerHTML =
          '<div style="text-align:center;padding:60px 20px">' +
            '<h2 style="color:#ea4335;margin-bottom:8px">Failed to load page</h2>' +
            '<p style="color:#6c757d">' + err.message + '</p>' +
            '<button class="btn btn-primary mt-2" onclick="location.reload()">Reload</button>' +
          '</div>';
        spaState.isLoading = false;
      });
  }

  function runPageScripts(container) {
    container.querySelectorAll("script").forEach(function(oldScr) {
      var scr = document.createElement("script");
      Array.from(oldScr.attributes).forEach(function(a) {
        scr.setAttribute(a.name, a.value);
      });
      scr.textContent = oldScr.textContent;
      oldScr.parentNode.replaceChild(scr, oldScr);
    });
  }

  function updateActiveSidebar(url) {
    var page = url.split("?")[0].replace(".html", "");
    if (page.indexOf("results/") === 0 || page === "results_patient" || page === "results_batch") page = "results";
    document.querySelectorAll(".sidebar-nav a").forEach(function(link) {
      var dp = link.getAttribute("data-page");
      link.classList.toggle("active", dp === page);
    });
  }

  function buildSkeleton() {
    return (
      '<div class="skel-wrap">' +
        '<div class="skel-line" style="width:36%;height:26px;margin-bottom:28px"></div>' +
        '<div class="skel-card" style="height:80px;margin-bottom:16px"></div>' +
        '<div class="skel-card" style="height:200px"></div>' +
      '</div>'
    );
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initSPA);
  } else {
    initSPA();
  }
})();
