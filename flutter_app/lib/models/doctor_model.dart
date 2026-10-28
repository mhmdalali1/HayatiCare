class DoctorModel {
  final int doctorId;
  final String firstName;
  final String lastName;
  final String specialization;

  String get fullName => 'Dr. ${[firstName, lastName].where((s) => s.isNotEmpty).join(' ')}';

  const DoctorModel({
    required this.doctorId,
    required this.firstName,
    required this.lastName,
    required this.specialization,
  })
  ;

  factory DoctorModel.fromJson(Map<String, dynamic> j) => DoctorModel(
    doctorId: j['doctor_id'] as int,
    firstName: (j['first_name'] as String?) ?? '',
    lastName: (j['last_name'] as String?) ?? '',
    specialization: (j['specialization'] as String?) ?? '',
  );
}
