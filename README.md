# HayatiCare

**Full-stack hospital management coursework project** — Flutter mobile client, Flask API, MySQL database, and browser-based dashboards.

> **Academic demonstration only.** This project is not approved for real patient data, clinical decisions, or production healthcare deployment. Features described below are implemented in source; production security and end-to-end behavior have not been independently certified.

## Overview

HayatiCare explores a role-based clinic workflow that connects patients, doctors, and secretaries. The system includes appointment handling, medical test records, reference-range checks, notifications, and a patient-facing mobile experience. Its educational chatbot is intended for application guidance and reference ranges, **not diagnosis**.

**Course:** COE461 Software Engineering, Lebanese American University, Spring 2026.

**Team:** Mohamad Al Ali · Mohammad Sinn · Ahmad Ghaddar · Omar Saadeh. This is a collaborative university project; individual contributions should be described separately when used in a portfolio.

## Technology

| Part | Stack |
| --- | --- |
| Backend API | Python, Flask, SQLAlchemy, Flask-JWT-Extended, Flask-CORS |
| Data | MySQL, SQL schema and application models |
| Mobile | Flutter/Dart, Dio, Riverpod, Flutter Secure Storage |
| Web dashboards | HTML, CSS and JavaScript |
| Additional modules | Rule-based reference-range checks and optional AI/chat components |

## Capabilities represented in the code

- Role-based patient, doctor, and secretary flows.
- Appointment, patient, and medical-result management.
- Lab reference-range handling and notification workflows.
- Mobile patient screens and separate browser-based staff dashboards.
- Authentication with hashed passwords and JWT-based access.

Implementations are educational and may require additional hardening, environment setup, or fixes before a full demonstration.

## Repository structure

```text
HayatiCare/
├── backend/                   # Flask API, models, services, SQL setup
│   ├── app/
│   ├── migrations/schema.sql
│   ├── requirements.txt
│   ├── run.py
│   └── seed_data.py          # Demonstration data ONLY
├── flutter_app/               # Patient mobile app (Flutter)
├── android/                   # Older native Android prototype
├── web/                       # Browser dashboards
├── knowledge/                 # Sample reference text
├── .env.example               # Placeholder configuration (no live secrets)
└── README.md
```

## Local setup (Windows / PowerShell)

### 1. Configure MySQL

Create a local MySQL database called `hmss_db` and an appropriately restricted local user. Import the schema:

```powershell
mysql -u YOUR_MYSQL_USER -p hmss_db < backend/migrations/schema.sql
```

The shell redirection above works in a terminal that supports `<` (for example, `cmd.exe`); in PowerShell, import the SQL using MySQL's `source` command or redirect through `cmd.exe`.

### 2. Configure the backend

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
cd ..
Copy-Item .env.example .env
```

Fill in your own database details and freshly generated independent secrets in `.env`. Never use the placeholder values in a real environment. Then start the backend:

```powershell
python backend/run.py
```

The development server listens on port 5000. The browser UI is served from the backend's root route where configured.

**Demo data:** `backend/seed_data.py` creates synthetic/example users and requires `DEMO_SEED_PASSWORD` (at least 12 characters) from the environment. `backend/seed_admin.py` requires `ADMIN_PASSWORD` (at least 12 characters). Set these only for a disposable, locally isolated database. Never run the seed utilities in production or with real user records.

### 3. Configure Flutter

```powershell
cd flutter_app
flutter pub get
flutter run
```

The default API URL is `http://10.0.2.2:5000` for the standard **Android emulator**. On a physical Android device connected to the same trusted LAN as the server, override it **without editing application source**:

```powershell
flutter run --dart-define="HAYATICARE_API_BASE_URL=http://YOUR_PC_LAN_IP:5000"
```

For example, replace `YOUR_PC_LAN_IP` with your development computer's reachable IPv4 address. Native iOS builds require macOS/Xcode.

## Checks

```powershell
# In flutter_app/
flutter analyze
flutter test

# From repository root (syntax check only)
python -m compileall -q backend
```

These commands do **not** replace integration testing with a real local MySQL instance and authenticated test accounts.

## Security and publication notes

- Never commit `.env`, private keys, real medical data, user databases, or build artifacts.
- The original university repository previously tracked environment configuration. If secrets were ever committed there, rotate them and coordinate history cleanup with collaborators. A fresh repository does not undo past exposure.
- The server's development defaults and wildcard CORS policy are **not** appropriate for public deployment as-is; apply proper security review, HTTPS, secret management, access controls, and healthcare privacy safeguards first.
- For portfolio screenshots, use fictional patients and sample records only.

## License and attribution

Academic team project, 2026. **No open-source license is granted by this README.** Confirm all teammates' permission and license choices before accepting external reuse or contributions.
