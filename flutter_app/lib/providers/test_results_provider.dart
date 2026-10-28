import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/test_result_model.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class TestResultsState {
  final List<TestResultModel> results;
  final bool isLoading;
  final String? error;

  const TestResultsState({
    this.results = const [],
    this.isLoading = false,
    this.error,
  });
}

class TestResultsNotifier extends StateNotifier<TestResultsState> {
  final ApiService _api;
  final int? _patientId;

  TestResultsNotifier(this._api, this._patientId)
      : super(const TestResultsState());

  Future<void> load() async {
    if (_patientId == null) return;
    state = TestResultsState(isLoading: true);
    try {
      final list = await _api.getMyTestResults(_patientId!);
      state = TestResultsState(results: list);
    } catch (e) {
      state = TestResultsState(error: e.toString());
    }
  }

}

final testResultsProvider =
    StateNotifierProvider<TestResultsNotifier, TestResultsState>((ref) {
  final patientId = ref.watch(authProvider).patientId;
  return TestResultsNotifier(ApiService(), patientId);
});

// ── Patient Batches (from PatientMedicalResult table) ───────────

class PatientBatchesState {
  final List<PatientBatch> batches;
  final bool isLoading;
  final String? error;

  const PatientBatchesState({
    this.batches = const [],
    this.isLoading = false,
    this.error,
  });
}

class PatientBatchResultsState {
  final List<PatientMedicalResult> results;
  final bool isLoading;
  final String? error;

  const PatientBatchResultsState({
    this.results = const [],
    this.isLoading = false,
    this.error,
  });
}

class PatientBatchesNotifier extends StateNotifier<PatientBatchesState> {
  final ApiService _api;
  final int? _patientId;

  PatientBatchesNotifier(this._api, this._patientId)
      : super(const PatientBatchesState());

  Future<void> load() async {
    if (_patientId == null) return;
    state = const PatientBatchesState(isLoading: true);
    try {
      final list = await _api.getPatientBatches(_patientId!);
      state = PatientBatchesState(batches: list);
    } catch (e) {
      state = PatientBatchesState(error: e.toString());
    }
  }
}

class PatientBatchResultsNotifier extends StateNotifier<PatientBatchResultsState> {
  final ApiService _api;

  PatientBatchResultsNotifier(this._api)
      : super(const PatientBatchResultsState());

  Future<void> load(int batchId) async {
    state = const PatientBatchResultsState(isLoading: true);
    try {
      final list = await _api.getBatchResults(batchId);
      state = PatientBatchResultsState(results: list);
    } catch (e) {
      state = PatientBatchResultsState(error: e.toString());
    }
  }
}

final patientBatchesProvider =
    StateNotifierProvider<PatientBatchesNotifier, PatientBatchesState>((ref) {
  final patientId = ref.watch(authProvider).patientId;
  return PatientBatchesNotifier(ApiService(), patientId);
});

final patientBatchResultsProvider =
    StateNotifierProvider<PatientBatchResultsNotifier, PatientBatchResultsState>((ref) {
  return PatientBatchResultsNotifier(ApiService());
});
