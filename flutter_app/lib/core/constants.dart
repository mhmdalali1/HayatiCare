class AppConstants {
  // Android emulator: 10.0.2.2 refers to the development machine.
  // For a physical phone, pass the machine's LAN address using --dart-define:
  // flutter run --dart-define=HAYATICARE_API_BASE_URL=http://192.168.1.10:5000
  static const String apiBaseUrl = String.fromEnvironment(
    'HAYATICARE_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_json';
  static const String patientIdKey = 'patient_id';
}
