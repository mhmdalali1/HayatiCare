import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';
import '../models/user_model.dart';
import '../models/doctor_model.dart';
import '../models/appointment_model.dart';
import '../models/test_result_model.dart';
import '../models/notification_model.dart';
import '../models/body_health_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _storage = const FlutterSecureStorage();
  late final Dio _dio = _buildDio();

  Dio _buildDio() {
    final dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _tryRefresh();
          if (refreshed) {
            // Retry with new token
            final token = await _storage.read(key: AppConstants.tokenKey);
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            try {
              final response = await dio.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            } catch (_) {}
          }
          await clearSession();
        }
        handler.next(error);
      },
    ));

    return dio;
  }

  Future<bool> _tryRefresh() async {
    final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
    if (refreshToken == null) return false;
    try {
      final resp = await Dio().post(
        '${AppConstants.apiBaseUrl}/api/auth/refresh',
        options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
      );
      final data = resp.data;
      if (data['success'] == true) {
        await _storage.write(
            key: AppConstants.tokenKey, value: data['data']['access_token']);
        return true;
      }
    } catch (_) {}
    return false;
  }

  // ── Auth ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    final resp = await _dio.post('/api/auth/login',
        data: {'email': email, 'password': password});
    return _handle(resp);
  }

  Future<Map<String, dynamic>> register(Map<String, String> data) async {
    final resp = await _dio.post('/api/auth/register', data: data);
    return _handle(resp);
  }

  Future<void> logout() async {
    try {
      await _dio.post('/api/auth/logout');
    } catch (_) {}
    await clearSession();
  }

  Future<void> saveSession(Map<String, dynamic> data) async {
    await _storage.write(key: AppConstants.tokenKey, value: data['access_token'] as String);
    await _storage.write(key: AppConstants.refreshTokenKey, value: data['refresh_token'] as String);
    await _storage.write(key: AppConstants.userKey, value: jsonEncode(data['user']));
  }

  Future<void> clearSession() async {
    await _storage.deleteAll();
  }

  Future<UserModel?> getSavedUser() async {
    final raw = await _storage.read(key: AppConstants.userKey);
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    return token != null && token.isNotEmpty;
  }

  // ── Patient ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAvailableDoctors() async {
    final resp = await _dio.get('/api/doctors/available');
    return _handle(resp);
  }

  Future<List<DoctorModel>> getAllDoctors() async {
    final resp = await _dio.get('/api/doctors');
    final data = _handle(resp);
    return (data['data'] as List)
        .map((e) => DoctorModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getMyProfile() async {
    final resp = await _dio.get('/api/patients/me');
    return _handle(resp);
  }

  Future<List<AppointmentModel>> getMyAppointments(int patientId) async {
    final resp = await _dio.get('/api/patients/$patientId/appointments');
    final data = _handle(resp);
    return (data['data'] as List)
        .map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> deleteAppointment(int appointmentId) async {
    final resp = await _dio.delete('/api/appointments/$appointmentId');
    return _handle(resp);
  }

  Future<List<TestResultModel>> getMyTestResults(int patientId) async {
    final resp = await _dio.get('/api/patients/$patientId/test-results');
    final data = _handle(resp);
    return (data['data'] as List)
        .map((e) => TestResultModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Appointments ──────────────────────────────────────────────

  Future<List<AppointmentModel>> getAppointments() async {
    final resp = await _dio.get('/api/appointments');
    final data = _handle(resp);
    return (data['data'] as List)
        .map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> createAppointment(Map<String, dynamic> body) async {
    final resp = await _dio.post('/api/appointments', data: body);
    return _handle(resp);
  }

  // ── Notifications ─────────────────────────────────────────────

  Future<List<NotificationModel>> getNotifications() async {
    final resp = await _dio.get('/api/notifications');
    final data = _handle(resp);
    return (data['data'] as List)
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markNotificationRead(int id) async {
    await _dio.put('/api/notifications/$id/read');
  }

  Future<void> deleteNotification(int id) async {
    await _dio.delete('/api/notifications/$id');
  }

  // ── Body Health ──────────────────────────────────────

  Future<BodyHealthModel?> getBodyHealth(int patientId) async {
    try {
      final resp = await _dio.get('/api/body-health/patient/$patientId');
      final data = _handle(resp);
      return BodyHealthModel.fromJson(data['data']);
    } catch (_) {
      return null;
    }
  }

  Future<BodyHealthModel?> updateBodyHealth(
    int patientId,
    Map<String, dynamic> body,
  ) async {
    try {
      final resp = await _dio.put(
        '/api/body-health/patient/$patientId',
        data: body,
      );
      final data = _handle(resp);
      return BodyHealthModel.fromJson(data['data']);
    } catch (_) {
      return null;
    }
  }

  // ── Chatbot ───────────────────────────────────────────────────

  Future<String> chatbotQuery(String query) async {
    final resp = await _dio.post('/api/chatbot/query', data: {'query': query});
    final data = _handle(resp);
    return (data['data']?['response_text'] as String?) ?? 'No response.';
  }

  Future<List<String>> getChatbotFaqs() async {
    try {
      final resp = await _dio.get('/api/chatbot/faqs');
      final data = _handle(resp);
      final topics = data['data']?['topics'] as List?;
      return topics?.map((e) => e.toString()).toList() ?? [];
    } catch (_) {
      return [];
    }
  }

  // ── Patient Medical Result Batches ────────────────────────────

  Future<List<PatientBatch>> getPatientBatches(int patientId) async {
    final resp = await _dio.get('/api/patient-results/patient/$patientId/batches');
    final data = _handle(resp);
    return (data['data'] as List)
        .map((e) => PatientBatch.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PatientMedicalResult>> getBatchResults(int batchId) async {
    final resp = await _dio.get('/api/patient-results/batch/$batchId');
    final data = _handle(resp);
    return (data['data'] as List)
        .map((e) => PatientMedicalResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Medical Tests ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMedicalTests() async {
    final resp = await _dio.get('/api/medical-tests');
    final data = _handle(resp);
    return List<Map<String, dynamic>>.from(data['data'] as List);
  }

  // ── Helper ────────────────────────────────────────────────────

  Map<String, dynamic> _handle(Response resp) {
    final body = resp.data as Map<String, dynamic>;
    if (body['success'] != true) {
      throw ApiException(body['message'] as String? ?? 'Request failed');
    }
    return body;
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
