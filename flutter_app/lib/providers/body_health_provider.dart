import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/body_health_model.dart';
import '../services/api_service.dart';

final bodyHealthProvider =
    StateNotifierProvider<BodyHealthNotifier, BodyHealthModel?>((ref) {
  return BodyHealthNotifier();
});

class BodyHealthNotifier extends StateNotifier<BodyHealthModel?> {
  BodyHealthNotifier() : super(null);

  Future<void> load(int patientId) async {
    final data = await ApiService().getBodyHealth(patientId);
    state = data;
  }

  Future<void> update(int patientId, {
    double? heightCm,
    double? weightKg,
    String? gender,
  }) async {
    final bmi = _calcBmi(heightCm ?? state?.heightCm, weightKg ?? state?.weightKg);
    final category = _bmiCategory(bmi);
    final calories = _calcCalories(weightKg ?? state?.weightKg);

    final body = <String, dynamic>{};
    if (heightCm != null) body['height_cm'] = heightCm;
    if (weightKg != null) body['weight_kg'] = weightKg;
    if (gender != null) body['gender'] = gender;
    if (bmi != null) {
      body['bmi'] = bmi;
      body['bmi_category'] = category;
    }
    if (calories != null) body['daily_calorie_limit'] = calories;

    final updated = await ApiService().updateBodyHealth(patientId, body);
    if (updated != null) {
      state = updated;
    } else {
      // Fallback: update local state
      state = BodyHealthModel(
        patientId: patientId,
        gender: gender ?? state?.gender,
        heightCm: heightCm ?? state?.heightCm,
        weightKg: weightKg ?? state?.weightKg,
        bmi: bmi,
        bmiCategory: category,
        dailyCalorieLimit: calories,
        lastUpdated: DateTime.now().toIso8601String(),
      );
    }
  }

  double? _calcBmi(double? heightCm, double? weightKg) {
    if (heightCm == null || weightKg == null || heightCm == 0) return null;
    final h = heightCm / 100;
    return weightKg / (h * h);
  }

  String? _bmiCategory(double? bmi) {
    if (bmi == null) return null;
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  int? _calcCalories(double? weightKg) {
    if (weightKg == null) return null;
    return (weightKg * 30).round();
  }
}
