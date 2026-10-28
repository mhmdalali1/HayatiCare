import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/appointment_model.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class AppointmentsState {
  final List<AppointmentModel> appointments;
  final bool isLoading;
  final String? error;

  const AppointmentsState({
    this.appointments = const [],
    this.isLoading = false,
    this.error,
  });

  List<AppointmentModel> get upcoming =>
      appointments.where((a) => a.isUpcoming).toList();
  List<AppointmentModel> get past =>
      appointments.where((a) => !a.isUpcoming).toList();
}

class AppointmentsNotifier extends StateNotifier<AppointmentsState> {
  final ApiService _api;
  final int? _patientId;

  AppointmentsNotifier(this._api, this._patientId)
      : super(const AppointmentsState());

  Future<void> load() async {
    if (_patientId == null) return;
    state = AppointmentsState(isLoading: true);
    try {
      final list = await _api.getMyAppointments(_patientId!);
      state = AppointmentsState(appointments: list);
    } catch (e) {
      state = AppointmentsState(error: e.toString());
    }
  }

  Future<String?> create(Map<String, dynamic> body) async {
    try {
      await _api.createAppointment(body);
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Failed to create appointment';
    }
  }

  Future<String?> delete(int appointmentId) async {
    try {
      await _api.deleteAppointment(appointmentId);
      await load();
      return null;
    } on ApiException catch (e) {
      print('ApiException deleting appointment: ${e.message}');
      return e.message;
    } catch (e) {
      print('Error deleting appointment: $e');
      return 'Failed to cancel appointment';
    }
  }
}

final appointmentsProvider =
    StateNotifierProvider<AppointmentsNotifier, AppointmentsState>((ref) {
  final patientId = ref.watch(authProvider).patientId;
  return AppointmentsNotifier(ApiService(), patientId);
});
