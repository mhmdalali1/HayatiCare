class BodyHealthModel {
  final int? bodyHealthId;
  final int patientId;
  final String? gender;
  final double? heightCm;
  final double? weightKg;
  final double? bmi;
  final String? bmiCategory;
  final int? dailyCalorieLimit;
  final String? lastUpdated;

  BodyHealthModel({
    this.bodyHealthId,
    required this.patientId,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.bmi,
    this.bmiCategory,
    this.dailyCalorieLimit,
    this.lastUpdated,
  });

  factory BodyHealthModel.fromJson(Map<String, dynamic> j) =>
      BodyHealthModel(
        bodyHealthId: j['body_health_id'] as int?,
        patientId: j['patient_id'] as int,
        gender: j['gender'] as String?,
        heightCm: (j['height_cm'] as num?)?.toDouble(),
        weightKg: (j['weight_kg'] as num?)?.toDouble(),
        bmi: (j['bmi'] as num?)?.toDouble(),
        bmiCategory: j['bmi_category'] as String?,
        dailyCalorieLimit: j['daily_calorie_limit'] as int?,
        lastUpdated: j['last_updated'] as String?,
      );

  Map<String, dynamic> toJson() =>
      {
        'gender': gender,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'bmi': bmi,
        'bmi_category': bmiCategory,
        'daily_calorie_limit': dailyCalorieLimit,
      };

  double? calculateBmi() {
    if (heightCm == null || weightKg == null || heightCm == 0) return null;
    final h = heightCm! / 100;
    return weightKg! / (h * h);
  }

  String? getBmiCategory() {
    final b = bmi ?? calculateBmi();
    if (b == null) return null;
    if (b < 18.5) return 'Underweight';
    if (b < 25) return 'Normal';
    if (b < 30) return 'Overweight';
    return 'Obese';
  }

  int? calculateCalorieLimit() {
    if (weightKg == null) return null;
    return (weightKg! * 30).round();
  }

}
