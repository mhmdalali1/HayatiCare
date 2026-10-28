class AppointmentModel {
  final int appointmentId;
  final int patientId;
  final int doctorId;
  final String? patientName;
  final String? doctorName;
  final String? specialty;
  final String? scheduledStart;
  final String? scheduledEnd;
  final String status;
  final String? reason;
  final String? location;
  final String? secretaryComment;


  const AppointmentModel({
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    this.patientName,
    this.doctorName,
    this.specialty,
    this.scheduledStart,
    this.scheduledEnd,
    required this.status,
    this.reason,
    this.location,
    this.secretaryComment,
  });

  bool get isUpcoming =>
      status == 'pending' || status == 'confirmed' || status == 'rescheduled';

  factory AppointmentModel.fromJson(Map<String, dynamic> j) => AppointmentModel(
        appointmentId: j['appointment_id'] as int,
        patientId: j['patient_id'] as int,
        doctorId: j['doctor_id'] as int,
        patientName: j['patient_name'] as String?,
        doctorName: j['doctor_name'] as String?,
        specialty: j['specialty'] as String?,
        scheduledStart: j['scheduled_start'] as String?,
        scheduledEnd: j['scheduled_end'] as String?,
        status: j['status'] as String? ?? 'pending',
        reason: j['reason'] as String?,
        location: j['location'] as String?,
        secretaryComment: j['secretary_comment'] as String?,
      );

  DateTime get date {
    if (scheduledStart == null) return DateTime.now();
    return DateTime.tryParse(scheduledStart!) ?? DateTime.now();
  }

  String get time {
    if (scheduledStart == null) return '';
    final dt = DateTime.tryParse(scheduledStart!);
    if (dt == null) return '';
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}
