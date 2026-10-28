# HayatiCare — Patient Mobile App

Flutter client for the HayatiCare academic hospital management project. See [the project README](../README.md) for the system overview, contributors, local backend requirements, security notes and setup.

## Run on Android

```powershell
flutter pub get
flutter run
```

By default, the app uses the Android emulator host address `http://10.0.2.2:5000`. To use a physical Android phone, run:

```powershell
flutter run --dart-define="HAYATICARE_API_BASE_URL=http://YOUR_PC_LAN_IP:5000"
```

Run the Flask backend on your trusted local network first. The mobile application is a coursework demonstration, not a clinical product.
