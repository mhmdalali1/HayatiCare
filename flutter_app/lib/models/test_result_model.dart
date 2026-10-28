class NormalRange {
  final double minValue;
  final double maxValue;
  final String? unit;

  const NormalRange({required this.minValue, required this.maxValue, this.unit});

  factory NormalRange.fromJson(Map<String, dynamic> j) => NormalRange(
        minValue: (j['min_value'] as num).toDouble(),
        maxValue: (j['max_value'] as num).toDouble(),
        unit: j['unit'] as String?,
      );

  String get display => '$minValue – $maxValue ${unit ?? ''}';
}

class PatientMedicalResult {
  final int resultId;
  final int patientId;
  final int testId;
  final String value;
  final String? unit;
  final String status;
  final int? createdByUserId;
  final int? batchId;
  final String? createdAt;
  final String? testCode;
  final String? testName;
  final String? defaultUnit;
  final String? patientName;
  final String? patientCode;

  const PatientMedicalResult({
    required this.resultId,
    required this.patientId,
    required this.testId,
    required this.value,
    this.unit,
    this.status = 'normal',
    this.createdByUserId,
    this.batchId,
    this.createdAt,
    this.testCode,
    this.testName,
    this.defaultUnit,
    this.patientName,
    this.patientCode,
  });

  factory PatientMedicalResult.fromJson(Map<String, dynamic> j) =>
      PatientMedicalResult(
        resultId: j['result_id'] as int,
        patientId: j['patient_id'] as int,
        testId: j['test_id'] as int,
        value: j['value'] as String? ?? '',
        unit: j['unit'] as String?,
        status: j['status'] as String? ?? 'normal',
        createdByUserId: j['created_by_user_id'] as int?,
        batchId: j['batch_id'] as int?,
        createdAt: j['created_at'] as String?,
        testCode: j['test_code'] as String?,
        testName: j['test_name'] as String?,
        defaultUnit: j['default_unit'] as String?,
        patientName: j['patient_name'] as String?,
        patientCode: j['patient_code'] as String?,
      );
}

class PatientBatch {
  final int batchId;
  final String? batchDate;
  final int resultCount;
  final String? patientName;
  final String? patientCode;

  const PatientBatch({
    required this.batchId,
    this.batchDate,
    required this.resultCount,
    this.patientName,
    this.patientCode,
  });

  factory PatientBatch.fromJson(Map<String, dynamic> j) => PatientBatch(
        batchId: j['batch_id'] as int,
        batchDate: j['batch_date'] as String?,
        resultCount: j['result_count'] as int? ?? 0,
        patientName: j['patient_name'] as String?,
        patientCode: j['patient_code'] as String?,
      );
}

class TestResultModel {
  final int resultId;
  final int patientId;
  final int doctorId;
  final int testId;
  final String? testName;
  final String? testCode;
  final String? resultDate;
  final double value;
  final String? unit;
  final String? fastingState;
  final String? status;
  final bool isFlagged;
  final String? notes;
  final NormalRange? normalRange;

  const TestResultModel({
    required this.resultId,
    required this.patientId,
    required this.doctorId,
    required this.testId,
    this.testName,
    this.testCode,
    this.resultDate,
    required this.value,
    this.unit,
    this.fastingState,
    this.status,
    required this.isFlagged,
    this.notes,
    this.normalRange,
  });

  factory TestResultModel.fromJson(Map<String, dynamic> j) =>
      TestResultModel(
        resultId: j['result_id'] as int,
        patientId: j['patient_id'] as int,
        doctorId: j['doctor_id'] as int,
        testId: j['test_id'] as int,
        testName: j['test_name'] as String?,
        testCode: j['test_code'] as String?,
        resultDate: j['result_date'] as String?,
        value: (j['value'] as num).toDouble(),
        unit: j['unit'] as String?,
        fastingState: j['fasting_state'] as String?,
        status: j['status'] as String?,
        isFlagged: j['is_flagged'] as bool? ?? false,
        notes: j['notes'] as String?,
        normalRange: j['normal_range'] != null
            ? NormalRange.fromJson(j['normal_range'] as Map<String, dynamic>)
            : null,
      );

}
