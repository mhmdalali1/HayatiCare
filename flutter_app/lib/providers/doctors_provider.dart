import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/doctor_model.dart';
import '../services/api_service.dart';

class DoctorsState {
  final List<DoctorModel> doctors;
  final bool isLoading;
  final String? error;

  const DoctorsState({
    this.doctors = const [],
    this.isLoading = false,
    this.error,
  });
}

class DoctorsNotifier extends StateNotifier<DoctorsState> {
  final ApiService _api;

  DoctorsNotifier(this._api) : super(const DoctorsState());

  Future<void> load() async {
    state = const DoctorsState(isLoading: true);
    try {
      final list = await _api.getAllDoctors();
      state = DoctorsState(doctors: list);
    } catch (e) {
      state = DoctorsState(error: e.toString());
    }
  }
}

final doctorsProvider = StateNotifierProvider<DoctorsNotifier, DoctorsState>((ref) {
  return DoctorsNotifier(ApiService());
});
