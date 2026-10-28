import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../providers/appointments_provider.dart';
import '../providers/auth_provider.dart';
import '../models/appointment_model.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../services/api_service.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Map<String, dynamic>> _doctors = [];
  bool _loadingDoctors = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(appointmentsProvider.notifier).load();
      _loadDoctors();
    });
  }

  Future<void> _loadDoctors() async {
    setState(() => _loadingDoctors = true);
    try {
      final resp = await ApiService().getAvailableDoctors();
      if (resp['success'] == true) {
        setState(() {
          _doctors = List<Map<String, dynamic>>.from(resp['data'] ?? []);
        });
      }
    } catch (_) {}
    setState(() => _loadingDoctors = false);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appointmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Appointments', style: AppTextStyles.titleLarge),
        centerTitle: false,
        actions: [
          if (_doctors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => _showCreateDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'New',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primaryBlue,
          indicatorWeight: 3,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: AppColors.textGrey,
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(appointmentsProvider.notifier).load(),
              child: TabBarView(
                controller: _tabs,
                children: [
                  _AppointmentList(
                    items: state.upcoming,
                    empty: 'No upcoming appointments',
                    emptyIcon: Icons.calendar_today_outlined,
                  ),
                  _AppointmentList(
                    items: state.past,
                    empty: 'No past appointments',
                    emptyIcon: Icons.history,
                  ),
                ],
              ),
            ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final patientId = ref.read(authProvider).patientId;
    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session error. Please log in again.')),
      );
      return;
    }

    if (_doctors.isEmpty && !_loadingDoctors) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No doctors available.')),
      );
      return;
    }

    int? selectedDoctorId;
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              left: 24,
              right: 24,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Book Appointment',
                      style: AppTextStyles.heading2,
                    ),
                    const SizedBox(height: 24),

                    // Doctor Selection
                    Text(
                      'Select Doctor',
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (_loadingDoctors)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      SizedBox(
                        height: 110,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _doctors.length,
                          itemBuilder: (_, i) {
                            final doctor = _doctors[i];
                            final isSelected =
                                selectedDoctorId == doctor['doctor_id'];
                            return GestureDetector(
                              onTap: () {
                                setSheetState(() {
                                  selectedDoctorId = doctor['doctor_id'];
                                });
                              },
                              child: Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryBlue
                                      : AppColors.backgroundGrey,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primaryBlue
                                        : AppColors.border,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white.withValues(alpha: 0.2)
                                            : AppColors.primaryBlue
                                                .withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.primaryBlue,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Dr. ${doctor['first_name']}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.textDark,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      doctor['specialization'] ?? '',
                                      style: GoogleFonts.poppins(
                                        fontSize: 9,
                                        color: isSelected
                                            ? Colors.white70
                                            : AppColors.textGrey,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    if (selectedDoctorId == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Please select a doctor',
                          style: GoogleFonts.poppins(
                            color: AppColors.errorRed,
                            fontSize: 12,
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Date Selection
                    Text(
                      'Select Date',
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: AppColors.primaryBlue,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          setSheetState(() {
                            selectedDate = date;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundGrey,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              selectedDate != null
                                  ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
                                  : 'Select date',
                              style: GoogleFonts.poppins(
                                color: selectedDate != null
                                    ? AppColors.textPrimary
                                    : AppColors.textHint,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Time Selection
                    Text(
                      'Select Time',
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: ctx,
                          initialTime: selectedTime ?? TimeOfDay.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: AppColors.primaryBlue,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (time != null) {
                          setSheetState(() {
                            selectedTime = time;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundGrey,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              selectedTime != null
                                  ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                                  : 'Select time',
                              style: GoogleFonts.poppins(
                                color: selectedTime != null
                                    ? AppColors.textPrimary
                                    : AppColors.textHint,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Reason
                    Text(
                      'Reason (optional)',
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: reasonCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g., Regular checkup',
                        hintStyle: AppTextStyles.subtitle,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (selectedDoctorId == null ||
                              selectedDate == null ||
                              selectedTime == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill all required fields'),
                              ),
                            );
                            return;
                          }

                          final scheduledStart =
                              '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}T${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}:00';

                          final err = await ref
                              .read(appointmentsProvider.notifier)
                              .create({
                            'patient_id': patientId,
                            'doctor_id': selectedDoctorId,
                            'scheduled_start': scheduledStart,
                            if (reasonCtrl.text.trim().isNotEmpty)
                              'reason': reasonCtrl.text.trim(),
                          });

                          if (err != null) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(err),
                                  backgroundColor: AppColors.errorRed,
                                ),
                              );
                            }
                          } else {
                            Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Appointment booked successfully!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          }
                        },
                        child: Text(
                          'Book Appointment',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AppointmentList extends StatelessWidget {
  final List<AppointmentModel> items;
  final String empty;
  final IconData emptyIcon;

  const _AppointmentList({
    required this.items,
    required this.empty,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                shape: BoxShape.circle,
                boxShadow: AppTheme.cardShadow,
              ),
              child: Icon(emptyIcon, size: 40, color: AppColors.textHint),
            ),
            const SizedBox(height: 16),
            Text(
              empty,
              style: AppTextStyles.bodyGrey,
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 200 + (i * 60)),
        curve: Curves.easeOut,
        builder: (context, v, child) {
          return Opacity(
            opacity: v,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - v)),
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _AppointmentCard(items[i]),
        ),
      ),
    );
  }
}

class _AppointmentCard extends ConsumerWidget {
  final AppointmentModel appt;
  const _AppointmentCard(this.appt);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _getStatusColor(appt.status);
    final statusBg = _getStatusBg(appt.status);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          appt.doctorName != null
                              ? 'Dr. ${appt.doctorName}'
                              : 'Doctor #${appt.doctorId}',
                          style: AppTextStyles.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    appt.status.toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.access_time,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    appt.scheduledStart ?? 'TBD',
                    style: AppTextStyles.bodyGrey,
                  ),
                ),
              ],
            ),
            if (appt.reason != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appt.reason!,
                      style: AppTextStyles.bodyGrey,
                    ),
                  ),
                ],
              ),
            ],
            if (appt.location != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    appt.location!,
                    style: AppTextStyles.bodyGrey,
                  ),
                ],
              ),
            ],
            if (appt.status != 'completed' &&
                appt.status != 'cancelled') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showCancelDialog(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.errorRed,
                    side: const BorderSide(color: AppColors.errorRed),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel Appointment',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppColors.statusConfirmed;
      case 'pending':
        return AppColors.statusPending;
      case 'cancelled':
        return AppColors.statusCancelled;
      case 'completed':
        return AppColors.primaryBlue;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getStatusBg(String status) {
    switch (status) {
      case 'confirmed':
        return AppColors.statusConfirmedBg;
      case 'pending':
        return AppColors.statusPendingBg;
      case 'cancelled':
        return const Color(0xFFFFEBEE);
      case 'completed':
        return const Color(0xFFE8F0FE);
      default:
        return AppColors.backgroundGrey;
    }
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text('Cancel Appointment', style: AppTextStyles.titleMedium),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'No',
              style: GoogleFonts.poppins(color: AppColors.textGrey),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final err = await ref
                  .read(appointmentsProvider.notifier)
                  .delete(appt.appointmentId);
              if (err != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err), backgroundColor: AppColors.errorRed),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Appointment cancelled'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: Text(
              'Yes, Cancel',
              style: GoogleFonts.poppins(
                color: AppColors.errorRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
