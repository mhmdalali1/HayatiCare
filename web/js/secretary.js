/**
 * secretary.js — Secretary dashboard
 */

function initSidebar(user) {
  var nameEl = document.getElementById("sidebar-user-name");
  if (nameEl && user) {
    nameEl.textContent = user.first_name + " " + user.last_name;
  }
}

var _apptRefreshInterval = null;

function startAutoRefresh() {
  if (_apptRefreshInterval) clearInterval(_apptRefreshInterval);
  _apptRefreshInterval = setInterval(function() {
    loadAppointments(true);
  }, 5000);
}

function stopAutoRefresh() {
  if (_apptRefreshInterval) {
    clearInterval(_apptRefreshInterval);
    _apptRefreshInterval = null;
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

function getCurrentUser() {
  try { return JSON.parse(localStorage.getItem("user")); } catch(e) { return null; }
}

function clearSession() {
  localStorage.removeItem("access_token");
  localStorage.removeItem("refresh_token");
  localStorage.removeItem("user");
}

// ===== Patients =====
function loadPatients() {
  var tbody = document.getElementById("patients-tbody");
  if (!tbody) return;
  tbody.innerHTML = "<tr><td colspan='7'>Loading...</td></tr>";

  api.get("/api/patients").then(function(data) {
    if (!data.success) {
      tbody.innerHTML = "<tr><td colspan='7'>Error</td></tr>";
      return;
    }
    tbody.innerHTML = "";
    var list = data.data || [];
    if (list.length === 0) {
      tbody.innerHTML = '<tr><td colspan="7">No patients</td></tr>';
      return;
    }
    list.forEach(function(p) {
      var tr = document.createElement("tr");
      tr.innerHTML =
        "<td>" + (p.patient_code || "?") + "</td>" +
        "<td>" + p.first_name + " " + p.last_name + "</td>" +
        "<td>" + (p.email || "?") + "</td>" +
        "<td>" + (p.date_of_birth || "?") + "</td>" +
        "<td>" + (p.gender || "?") + "</td>" +
        "<td>Active</td>" +
        "<td><button class=\"btn btn-sm btn-danger\" onclick=\"deletePatient(" + p.patient_id + ")\">Delete</button></td>";
      tbody.appendChild(tr);
    });
  });
}

function deletePatient(id) {
  if (!confirm("Delete this patient?")) return;
  api.delete("/api/patients/" + id).then(function(data) {
    showToast(data.message, data.success ? "success" : "error");
    if (data.success) loadPatients();
  });
}

function openCreatePatient() { document.getElementById("modal-create-patient").classList.add("open"); }
function closeCreatePatient() { document.getElementById("modal-create-patient").classList.remove("open"); }

function submitCreatePatient() {
  var email = document.getElementById("p-email").value;
  var password = document.getElementById("p-password").value;

  if (!email || !password) {
    showToast("Email and password are required", "error");
    return;
  }

  console.log("Creating patient with:", { email: email });

  var payload = {
    email: email,
    password: password,
    first_name: document.getElementById("p-first-name").value || "First",
    last_name: document.getElementById("p-last-name").value || "Last",
    phone: document.getElementById("p-phone").value,
    date_of_birth: document.getElementById("p-dob").value,
    gender: document.getElementById("p-gender").value,
    blood_type: document.getElementById("p-blood").value
  };


  api.post("/api/patients", payload).then(function(data) {
    console.log("Response:", data);
    showToast(data.message || (data.success ? "Patient created" : "Error"), data.success ? "success" : "error");
    if (data.success) {
      closeCreatePatient();
      loadPatients();
      document.getElementById("p-email").value = "";
      document.getElementById("p-password").value = "";
      document.getElementById("p-first-name").value = "";
      document.getElementById("p-last-name").value = "";
    }
  }).catch(function(err) {
    console.error("Error:", err);
    showToast("Error: " + err, "error");
  });
}

// ===== Doctors =====
function loadDoctors() {
  var tbody = document.getElementById("doctors-tbody");
  if (!tbody) return;
  tbody.innerHTML = "<tr><td colspan='6'>Loading...</td></tr>";

  api.get("/api/doctors").then(function(data) {
    if (!data.success) {
      tbody.innerHTML = "<tr><td colspan='6'>Error: " + data.message + "</td></tr>";
      return;
    }
    tbody.innerHTML = "";
    var list = data.data || [];
    if (list.length === 0) {
      tbody.innerHTML = '<tr><td colspan="6">No doctors</td></tr>';
      return;
    }
    list.forEach(function(d) {
      var tr = document.createElement("tr");
      tr.innerHTML =
        "<td>Dr. " + d.first_name + " " + d.last_name + "</td>" +
        "<td>" + (d.email || "?") + "</td>" +
        "<td>" + (d.specialization || "?") + "</td>" +
        "<td>" + (d.license_number || "?") + "</td>" +
        "<td>" + (d.office_room || "?") + "</td>" +
        "<td><button class=\"btn btn-sm btn-danger\" onclick=\"deleteDoctor(" + d.doctor_id + ")\">Delete</button></td>";
      tbody.appendChild(tr);
    });
  });
}

function deleteDoctor(id) {
  if (!confirm("Delete this doctor?")) return;
  api.delete("/api/doctors/" + id).then(function(data) {
    showToast(data.message, data.success ? "success" : "error");
    if (data.success) loadDoctors();
  });
}

function openCreateDoctor() { document.getElementById("modal-create-doctor").classList.add("open"); }
function closeCreateDoctor() { document.getElementById("modal-create-doctor").classList.remove("open"); }

function submitCreateDoctor() {
  if (!document.getElementById("d-email").value || !document.getElementById("d-password").value) {
    showToast("Email and password required", "error");
    return;
  }
  api.post("/api/doctors", {
    email: document.getElementById("d-email").value,
    password: document.getElementById("d-password").value,
    first_name: document.getElementById("d-first-name").value || "Test",
    last_name: document.getElementById("d-last-name").value || "Doctor",
    phone: document.getElementById("d-phone").value,
    specialization: document.getElementById("d-specialization").value,
    license_number: document.getElementById("d-license").value,
    office_room: document.getElementById("d-room").value
  }).then(function(data) {
    showToast(data.message, data.success ? "success" : "error");
    if (data.success) { closeCreateDoctor(); loadDoctors(); }
  });
}

// ===== Appointments =====
function loadAppointments(isAutoRefresh) {
  var tbody = document.getElementById("appt-tbody");
  if (!tbody) return;

  if (!isAutoRefresh) {
    tbody.innerHTML = "<tr><td colspan='8'>Loading...</td></tr>";
  }

  api.get("/api/appointments").then(function(data) {
    if (!data.success) {
      if (!isAutoRefresh) {
        tbody.innerHTML = "<tr><td colspan='8'>Error: " + data.message + "</td></tr>";
      }
      return;
    }
    tbody.innerHTML = "";
    var list = data.data || [];
    if (list.length === 0) {
      tbody.innerHTML = '<tr><td colspan="8">No appointments</td></tr>';
      return;
    }
    list.forEach(function(a) {
      var tr = document.createElement("tr");
tr.innerHTML =
        "<td>" + (a.patient_name || "?") + "</td>" +
        "<td>" + (a.doctor_name || "?") + "</td>" +
        "<td>" + new Date(a.scheduled_start).toLocaleString() + "</td>" +
        "<td>" + (a.scheduled_end ? new Date(a.scheduled_end).toLocaleString() : "—") + "</td>" +
        "<td>" + (a.reason || "—") + "</td>" +
        "<td>" + (a.location || "—") + "</td>" +
        "<td><span class='badge badge-" + a.status + "'>" + a.status + "</span></td>" +
        "<td>" +
          "<button class='btn btn-sm btn-outline' onclick='openEditAppt(" + a.appointment_id + ")'>Edit</button> " +
          "<button class='btn btn-sm btn-danger' onclick='deleteApp(" + a.appointment_id + ")'>Delete</button>" +
        "</td>";
      tbody.appendChild(tr);
    });
  });
}

function deleteApp(id) {
  if (!confirm("Delete appointment?")) return;
  api.delete("/api/appointments/" + id).then(function(data) {
    showToast(data.message, data.success ? "success" : "error");
    if (data.success) loadAppointments();
  });
}

function openEditAppt(id) {
  stopAutoRefresh();
  var apptId = id || parseInt(document.getElementById("edit-appt-id").value);

  api.get("/api/appointments/" + apptId).then(function(data) {
    if (!data.success) {
      showToast(data.message, "error");
      return;
    }
    var a = data.data;

    document.getElementById("edit-appt-id").value = a.appointment_id;
    document.getElementById("edit-appt-patient").value = a.patient_name || "";
    document.getElementById("edit-appt-doctor").value = a.doctor_name || "";
    document.getElementById("edit-doctor-id").value = a.doctor_id || "";
    document.getElementById("edit-patient-id").value = a.patient_id || "";
    document.getElementById("edit-appt-reason").value = a.reason || "";
    document.getElementById("edit-appt-status").value = a.status || "pending";
    document.getElementById("edit-appt-comment").value = a.secretary_comment || "";

    var doctor = a.doctor_office_room ? { office_room: a.doctor_office_room } : null;
    rebuildLocationDropdown("edit-appt-location", doctor, a.location || "");

    // Initialize edit date/time state
    _editApptId = a.appointment_id;
    _editDoctorId = a.doctor_id;
    _editPatientId = a.patient_id;
    _editDateOffset = 0;
    _editSelectedDate = null;
    _editSelectedTime = null;
    _editBookedSlots = [];

    // Preselect date if appointment has a scheduled start
    if (a.scheduled_start) {
      var apptDate = new Date(a.scheduled_start);
      var apptDateStr = _dateStr(apptDate);
      var apptHour = apptDate.getHours();
      var apptTimeStr = String(apptHour).padStart(2,"0") + ":00";

      _editSelectedDate = apptDateStr;
      _editSelectedTime = apptTimeStr;

      // Calculate offset to include the appointment date
      var today = new Date();
      var diffDays = Math.floor((apptDate - today) / 86400000);
      _editDateOffset = diffDays > 0 ? Math.floor(diffDays / 7) * 7 : 0;

      // Set hidden fields
      _setEditHiddenTimes(apptDateStr, apptTimeStr);
    }

    _renderDateCards("edit-date-cards", _editSelectedDate, _editDateOffset, selectEditDate);

    // Load slots for this doctor/patient
    loadEditSlots();

    document.getElementById("modal-edit-appt").classList.add("open");
  });
}

function closeEditAppt() {
  document.getElementById("modal-edit-appt").classList.remove("open");
  document.getElementById("edit-appt-id").value = "";
  document.getElementById("edit-appt-patient").value = "";
  document.getElementById("edit-appt-doctor").value = "";
  document.getElementById("edit-appt-start").value = "";
  document.getElementById("edit-appt-end").value = "";
  document.getElementById("edit-appt-reason").value = "";
  document.getElementById("edit-appt-location").value = "";
  document.getElementById("edit-appt-status").value = "pending";
  document.getElementById("edit-appt-comment").value = "";
  document.getElementById("edit-doctor-id").value = "";
  document.getElementById("edit-patient-id").value = "";
  _editApptId = null;
  _editDoctorId = null;
  _editPatientId = null;
  _editDateOffset = 0;
  _editSelectedDate = null;
  _editSelectedTime = null;
  _editBookedSlots = [];
  startAutoRefresh();
}

function submitEditAppt() {
  var apptId = parseInt(document.getElementById("edit-appt-id").value);
  if (!apptId) {
    showToast("Invalid appointment ID", "error");
    return;
  }

  var start = document.getElementById("edit-appt-start").value;
  if (!start) {
    showToast("Start time is required", "error");
    return;
  }

  if (!_editSelectedTime) {
    showToast("Please select an available time slot", "error");
    return;
  }

  for (var i = 0; i < _editBookedSlots.length; i++) {
    if (_editBookedSlots[i].time === _editSelectedTime && _editBookedSlots[i].status === "booked") {
      showToast("This time slot is no longer available", "error");
      return;
    }
  }

  var payload = {
    scheduled_start: start,
    scheduled_end: document.getElementById("edit-appt-end").value,
    reason: document.getElementById("edit-appt-reason").value,
    location: document.getElementById("edit-appt-location").value,
    status: document.getElementById("edit-appt-status").value,
    secretary_comment: document.getElementById("edit-appt-comment").value
  };

  api.put("/api/appointments/" + apptId, payload).then(function(data) {
    showToast(data.message, data.success ? "success" : "error");
    if (data.success) {
      closeEditAppt();
      loadAppointments();
    }
  });
}

function openCreateAppt() {
  stopAutoRefresh();
  var pSel = document.getElementById("appt-patient-id");
  var dSel = document.getElementById("appt-doctor-id");
  pSel.innerHTML = "<option value=''>Select Patient</option>";
  dSel.innerHTML = "<option value=''>Select Doctor</option>";

  // Store doctors for later use
  window._doctorsList = [];

  api.get("/api/patients").then(function(data) {
    if (data.success) data.data.forEach(function(p) {
      var opt = document.createElement("option");
      opt.value = p.patient_id;
      opt.textContent = p.first_name + " " + p.last_name;
      pSel.appendChild(opt);
    });
  });

  api.get("/api/doctors").then(function(data) {
    if (data.success) {
      window._doctorsList = data.data || [];
      data.data.forEach(function(d) {
        var opt = document.createElement("option");
        opt.value = d.doctor_id;
        opt.textContent = "Dr. " + d.first_name + " " + d.last_name + " (" + (d.specialization || "?") + ")";
        opt.dataset.officeRoom = d.office_room || "";
        dSel.appendChild(opt);
      });
    }
  });

  rebuildLocationDropdown("appt-location", null, "");
  initCreateDatePicker();
  document.getElementById("modal-create-appt").classList.add("open");
}

function closeCreateAppt() {
  document.getElementById("modal-create-appt").classList.remove("open");
  document.getElementById("appt-patient-id").value = "";
  document.getElementById("appt-doctor-id").value = "";
  document.getElementById("appt-start").value = "";
  document.getElementById("appt-end").value = "";
  document.getElementById("appt-reason").value = "";
  document.getElementById("appt-location").value = "";
  _apptDateOffset = 0;
  _apptSelectedDate = null;
  _apptSelectedTime = null;
  _apptBookedSlots = [];
  startAutoRefresh();
}

// ── Date/time picker helpers ──
var _DAY_NAMES = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"];
var _MONTH_NAMES = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
var _SLOT_HOURS = [9,10,11,12,13,14,15,16];

function _dateStr(d) {
  var m = String(d.getMonth() + 1).padStart(2,"0");
  var day = String(d.getDate()).padStart(2,"0");
  return d.getFullYear() + "-" + m + "-" + day;
}

function _renderDateCards(containerId, selectedDate, offset, onClick) {
  var container = document.getElementById(containerId);
  if (!container) return;
  container.innerHTML = "";
  for (var i = offset; i < offset + 7; i++) {
    var d = new Date();
    d.setDate(d.getDate() + i);
    var ds = _dateStr(d);
    var card = document.createElement("div");
    card.className = "date-card" + (ds === selectedDate ? " selected" : "");
    card.innerHTML = '<span class="date-card-day">' + _DAY_NAMES[d.getDay()] + '</span><span class="date-card-num">' + d.getDate() + '</span><span class="date-card-month">' + _MONTH_NAMES[d.getMonth()] + '</span>';
    card.onclick = (function(ds) { return function() { onClick(ds); }; })(ds);
    container.appendChild(card);
  }
}

function _renderTimeSlots(containerId, hasData, slots, selectedTime) {
  var container = document.getElementById(containerId);
  if (!container) return;
  if (!hasData) {
    container.innerHTML = '<div class="time-slot-placeholder">Select patient and doctor to view available times.</div>';
    return;
  }
  container.innerHTML = "";
  for (var i = 0; i < _SLOT_HOURS.length; i++) {
    var h = _SLOT_HOURS[i];
    var timeStr = String(h).padStart(2,"0") + ":00";
    var ampm = h < 12 ? "AM" : "PM";
    var displayH = h === 0 ? 12 : (h > 12 ? h - 12 : h);
    var isBooked = false;
    if (slots) {
      for (var j = 0; j < slots.length; j++) {
        if (slots[j].time === timeStr && slots[j].status === "booked") {
          isBooked = true;
          break;
        }
      }
    }
    var isSelected = timeStr === selectedTime;
    var el = document.createElement("div");
    el.className = "time-slot";
    if (isBooked) el.className += " booked";
    if (isSelected) el.className += " selected";
    el.innerHTML = '<span class="slot-hour">' + displayH + '</span><span class="slot-ampm">' + ampm + '</span>';
    if (isBooked) {
      var label = document.createElement("span");
      label.className = "slot-booked-label";
      label.textContent = "BOOKED";
      el.appendChild(label);
    }
    if (!isBooked) {
      el.onclick = (function(ts) {
        return function() {
          if (containerId.indexOf("edit-") === 0) {
            selectEditTime(ts);
          } else {
            selectCreateTime(ts);
          }
        };
      })(timeStr);
    }
    container.appendChild(el);
  }
}

function _setApptHiddenTimes(dateStr, timeStr) {
  if (!dateStr || !timeStr) {
    document.getElementById("appt-start").value = "";
    document.getElementById("appt-end").value = "";
    return;
  }
  var h = parseInt(timeStr.split(":")[0]);
  var start = new Date(dateStr + "T" + String(h).padStart(2,"0") + ":00:00");
  var end = new Date(start.getTime() + 3600000);
  document.getElementById("appt-start").value = start.toISOString();
  document.getElementById("appt-end").value = end.toISOString();
}

function _setEditHiddenTimes(dateStr, timeStr) {
  if (!dateStr || !timeStr) {
    document.getElementById("edit-appt-start").value = "";
    document.getElementById("edit-appt-end").value = "";
    return;
  }
  var h = parseInt(timeStr.split(":")[0]);
  var start = new Date(dateStr + "T" + String(h).padStart(2,"0") + ":00:00");
  var end = new Date(start.getTime() + 3600000);
  document.getElementById("edit-appt-start").value = start.toISOString();
  document.getElementById("edit-appt-end").value = end.toISOString();
}

// ── Create modal date/time state ──
var _apptDateOffset = 0;
var _apptSelectedDate = null;
var _apptSelectedTime = null;
var _apptBookedSlots = [];

function initCreateDatePicker() {
  _apptDateOffset = 0;
  _apptSelectedDate = null;
  _apptSelectedTime = null;
  _apptBookedSlots = [];
  _setApptHiddenTimes(null, null);
  _renderDateCards("date-cards", null, 0, selectCreateDate);
  _renderTimeSlots("time-slots", false, null, null);
}

function selectCreateDate(dateStr) {
  _apptSelectedDate = dateStr;
  _apptSelectedTime = null;
  _setApptHiddenTimes(null, null);
  _renderDateCards("date-cards", dateStr, _apptDateOffset, selectCreateDate);
  loadCreateSlots();
}

function prevDate() {
  if (_apptDateOffset > 0) {
    _apptDateOffset = Math.max(0, _apptDateOffset - 7);
    _renderDateCards("date-cards", _apptSelectedDate, _apptDateOffset, selectCreateDate);
    if (_apptSelectedDate) loadCreateSlots();
  }
}

function nextDate() {
  _apptDateOffset += 7;
  _renderDateCards("date-cards", _apptSelectedDate, _apptDateOffset, selectCreateDate);
  if (_apptSelectedDate) loadCreateSlots();
}

function selectCreateTime(timeStr) {
  _apptSelectedTime = timeStr;
  _setApptHiddenTimes(_apptSelectedDate, timeStr);
  _renderTimeSlots("time-slots", true, _apptBookedSlots, timeStr);
}

function loadCreateSlots() {
  var dId = parseInt(document.getElementById("appt-doctor-id").value);
  var pId = parseInt(document.getElementById("appt-patient-id").value);
  if (!dId || !pId || !_apptSelectedDate) {
    _apptBookedSlots = [];
    _apptSelectedTime = null;
    _setApptHiddenTimes(null, null);
    _renderTimeSlots("time-slots", false, null, null);
    return;
  }
  var url = "/api/appointments/slots?doctor_id=" + dId + "&patient_id=" + pId + "&date=" + _apptSelectedDate;
  api.get(url).then(function(data) {
    if (data.success) {
      _apptBookedSlots = data.data.slots || [];
      var timeStillValid = false;
      if (_apptSelectedTime) {
        for (var i = 0; i < _apptBookedSlots.length; i++) {
          if (_apptBookedSlots[i].time === _apptSelectedTime && _apptBookedSlots[i].status === "booked") {
            timeStillValid = false;
            break;
          }
          if (_apptBookedSlots[i].time === _apptSelectedTime && _apptBookedSlots[i].status === "available") {
            timeStillValid = true;
          }
        }
      }
      if (!timeStillValid && _apptSelectedTime) {
        _apptSelectedTime = null;
        _setApptHiddenTimes(null, null);
      }
      _renderTimeSlots("time-slots", true, _apptBookedSlots, _apptSelectedTime);
    }
  });
}

// ── Edit modal date/time state ──
var _editDateOffset = 0;
var _editSelectedDate = null;
var _editSelectedTime = null;
var _editBookedSlots = [];
var _editApptId = null;
var _editDoctorId = null;
var _editPatientId = null;

function initEditDatePicker() {
  _editDateOffset = 0;
  _editSelectedDate = null;
  _editSelectedTime = null;
  _editBookedSlots = [];
  _setEditHiddenTimes(null, null);
  _renderDateCards("edit-date-cards", null, 0, selectEditDate);
  _renderTimeSlots("edit-time-slots", false, null, null);
}

function selectEditDate(dateStr) {
  _editSelectedDate = dateStr;
  _editSelectedTime = null;
  _setEditHiddenTimes(null, null);
  _renderDateCards("edit-date-cards", dateStr, _editDateOffset, selectEditDate);
  loadEditSlots();
}

function prevDateEdit() {
  if (_editDateOffset > 0) {
    _editDateOffset = Math.max(0, _editDateOffset - 7);
    _renderDateCards("edit-date-cards", _editSelectedDate, _editDateOffset, selectEditDate);
    if (_editSelectedDate) loadEditSlots();
  }
}

function nextDateEdit() {
  _editDateOffset += 7;
  _renderDateCards("edit-date-cards", _editSelectedDate, _editDateOffset, selectEditDate);
  if (_editSelectedDate) loadEditSlots();
}

function selectEditTime(timeStr) {
  _editSelectedTime = timeStr;
  _setEditHiddenTimes(_editSelectedDate, timeStr);
  _renderTimeSlots("edit-time-slots", true, _editBookedSlots, timeStr);
}

function loadEditSlots() {
  var dId = _editDoctorId;
  var pId = _editPatientId;
  if (!dId || !_editSelectedDate) {
    _editBookedSlots = [];
    _editSelectedTime = null;
    _setEditHiddenTimes(null, null);
    _renderTimeSlots("edit-time-slots", false, null, null);
    return;
  }
  var url = "/api/appointments/slots?doctor_id=" + dId + "&date=" + _editSelectedDate;
  if (pId) url += "&patient_id=" + pId;
  if (_editApptId) url += "&exclude_id=" + _editApptId;
  api.get(url).then(function(data) {
    if (data.success) {
      _editBookedSlots = data.data.slots || [];
      var timeStillValid = false;
      if (_editSelectedTime) {
        for (var i = 0; i < _editBookedSlots.length; i++) {
          if (_editBookedSlots[i].time === _editSelectedTime && _editBookedSlots[i].status === "booked") {
            timeStillValid = false;
            break;
          }
          if (_editBookedSlots[i].time === _editSelectedTime && _editBookedSlots[i].status === "available") {
            timeStillValid = true;
          }
        }
      }
      if (!timeStillValid && _editSelectedTime) {
        _editSelectedTime = null;
        _setEditHiddenTimes(null, null);
      }
      _renderTimeSlots("edit-time-slots", true, _editBookedSlots, _editSelectedTime);
    }
  });
}

var _otherLocations = [
  { value: "Doctor's Office", text: "Doctor's Office" },
  { value: "Room 101", text: "Room 101" },
  { value: "Room 102", text: "Room 102" },
  { value: "Room 103", text: "Room 103" },
  { value: "Lab", text: "Lab" }
];

function rebuildLocationDropdown(selectId, doctor, preserveValue) {
  var sel = document.getElementById(selectId);
  if (!sel) return;
  var currentVal = preserveValue !== undefined ? preserveValue : sel.value;
  sel.innerHTML = '<option value="">Select location</option>';
  if (doctor && doctor.office_room) {
    var opt = document.createElement("option");
    opt.value = doctor.office_room;
    opt.textContent = doctor.office_room + " \u2014 Original Room";
    sel.appendChild(opt);
  }
  _otherLocations.forEach(function(loc) {
    var opt = document.createElement("option");
    opt.value = loc.value;
    opt.textContent = loc.text;
    sel.appendChild(opt);
  });
  if (currentVal) {
    try { sel.value = currentVal; } catch(e) {}
  }
}

function onDoctorChange(el) {
  var sel = el.target || el;
  var dId = parseInt(sel.value);
  var doctors = window._doctorsList || [];
  var doctor = null;
  if (dId) {
    doctor = doctors.find(function(d) { return d.doctor_id === dId; }) || null;
  }
  rebuildLocationDropdown("appt-location", doctor, "");
  _apptSelectedTime = null;
  _setApptHiddenTimes(null, null);
  loadCreateSlots();
}

function onPatientChange(el) {
  _apptSelectedTime = null;
  _setApptHiddenTimes(null, null);
  loadCreateSlots();
}

function submitCreateAppt() {
  var pId = parseInt(document.getElementById("appt-patient-id").value);
  var dId = parseInt(document.getElementById("appt-doctor-id").value);
  var start = document.getElementById("appt-start").value;
  var end = document.getElementById("appt-end").value;

  if (!pId || !dId || !start) {
    showToast("Patient, Doctor, and Start time are required", "error");
    return;
  }

  if (!_apptSelectedTime) {
    showToast("Please select an available time slot", "error");
    return;
  }

  for (var i = 0; i < _apptBookedSlots.length; i++) {
    if (_apptBookedSlots[i].time === _apptSelectedTime && _apptBookedSlots[i].status === "booked") {
      showToast("This time slot is no longer available", "error");
      return;
    }
  }

  var payload = {
    patient_id: pId,
    doctor_id: dId,
    scheduled_start: start,
    scheduled_end: end,
    reason: document.getElementById("appt-reason").value
  };

  var location = document.getElementById("appt-location").value;
  if (location) {
    payload.location = location;
  }

  api.post("/api/appointments", payload).then(function(data) {
    showToast(data.message, data.success ? "success" : "error");
    if (data.success) { closeCreateAppt(); loadAppointments(); }
  });
}

// ===== Notifications =====
function loadNotifications() {
  var tbody = document.getElementById("notif-tbody");
  if (!tbody) return;
  tbody.innerHTML = "<tr><td colspan='5'>Loading...</td></tr>";

  api.get("/api/notifications").then(function(data) {
    if (!data.success) {
      tbody.innerHTML = "<tr><td colspan='5'>Error: " + data.message + "</td></tr>";
      return;
    }
    tbody.innerHTML = "";
    var list = data.data || [];
    if (list.length === 0) {
      tbody.innerHTML = '<tr><td colspan="5">No notifications</td></tr>';
      return;
    }
    list.forEach(function(n) {
      var tr = document.createElement("tr");
      tr.className = n.is_read ? "" : "unread";
      tr.innerHTML =
        "<td><span class='badge badge-" + (n.type || "info") + "'>" + (n.type || "info") + "</span></td>" +
        "<td>" + (n.title || "—") + "</td>" +
        "<td>" + (n.message || "—") + "</td>" +
        "<td>" + new Date(n.created_at).toLocaleString() + "</td>" +
        "<td>" +
          (n.is_read
            ? "<span class='badge badge-secondary'>Read</span>"
            : "<button class='btn btn-sm btn-outline' onclick='markNotifRead(" + n.notification_id + ")'>Mark Read</button>"
          ) +
        "</td>";
      tbody.appendChild(tr);
    });
  });
}

function markNotifRead(id) {
  api.put("/api/notifications/" + id + "/read").then(function(data) {
    if (data.success) loadNotifications();
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
    if (!user || user.role !== "secretary") {
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
    if (page === "test_detail") page = "results";
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