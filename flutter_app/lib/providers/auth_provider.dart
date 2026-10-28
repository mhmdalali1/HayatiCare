import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthState {
  final UserModel? user;
  final int? patientId;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.patientId,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    int? patientId,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearUser = false,
  }) =>
      AuthState(
        user: clearUser ? null : (user ?? this.user),
        patientId: clearUser ? null : (patientId ?? this.patientId),
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;

  AuthNotifier(this._api) : super(const AuthState());

  Future<void> checkAuth() async {
    if (await _api.isLoggedIn()) {
      final user = await _api.getSavedUser();
      if (user != null) {
        // Fetch patient profile to get patient_id
        try {
          final profile = await _api.getMyProfile();
          final pid = profile['data']['patient_id'] as int?;
          state = state.copyWith(user: user, patientId: pid);
        } catch (_) {
          state = state.copyWith(user: user);
        }
      }
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final resp = await _api.login(email, password);
      final data = resp['data'] as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      if (user.role != 'patient') {
        state = state.copyWith(
          isLoading: false,
          error: 'This app is for patients only.\nPlease use the web portal.',
        );
        return false;
      }

      await _api.saveSession(data);
      final profile = await _api.getMyProfile();
      final pid = profile['data']['patient_id'] as int?;

      state = state.copyWith(user: user, patientId: pid, isLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Login error: $e',
      );
      return false;
    }
  }

  Future<bool> register(Map<String, String> data) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final resp = await _api.register(data);
      final respData = resp['data'] as Map<String, dynamic>;
      final user = UserModel.fromJson(respData['user'] as Map<String, dynamic>);

      await _api.saveSession(respData);
      final profile = await _api.getMyProfile();
      final pid = profile['data']['patient_id'] as int?;

      state = state.copyWith(user: user, patientId: pid, isLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      String msg = 'Register error: $e';
      if (e is DioException && e.response?.data != null) {
        final body = e.response!.data;
        if (body is Map && body['message'] != null) {
          msg = body['message'].toString();
        }
      }
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  Future<void> logout() async {
    await _api.logout();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ApiService());
});
