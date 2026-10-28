import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/appointments_provider.dart';
import '../providers/test_results_provider.dart';
import '../providers/notifications_provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../providers/doctors_provider.dart';
import '../models/test_result_model.dart';
import 'home_test_screen.dart' show MyTestResultsScreen;
import 'appointments_screen.dart';
import 'notifications_screen.dart';
import 'batch_detail_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = [
    'All',
    'Cardiology',
    'Dermatology',
    'Neurology',
    'General',
    'Pediatrics',
  ];
  final Set<int> _pinnedDoctorIds = {};

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(appointmentsProvider.notifier).load();
      ref.read(testResultsProvider.notifier).load();
      ref.read(patientBatchesProvider.notifier).load();
      ref.read(doctorsProvider.notifier).load();
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning!';
    if (hour < 17) return 'Good Afternoon!';
    return 'Good Evening!';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppColors.statusConfirmed;
      case 'pending':
        return AppColors.statusPending;
      case 'cancelled':
        return AppColors.statusCancelled;
      default:
        return AppColors.textGrey;
    }
  }

  Color _getStatusBg(String status) {
    switch (status) {
      case 'confirmed':
        return AppColors.statusConfirmedBg;
      case 'pending':
        return AppColors.statusPendingBg;
      case 'cancelled':
        return AppColors.statusCancelledBg;
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  Future<void> _showLogoutDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final notifs = ref.watch(notificationsProvider);
    final appts = ref.watch(appointmentsProvider);
    final batches = ref.watch(patientBatchesProvider);
    final doctorsState = ref.watch(doctorsProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGrey,
      drawer: _buildSidebar(user),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(user, notifs),
                const SizedBox(height: 24),
                Text(
                  'How are you\nfeeling today?',
                  style: AppTextStyles.heading1,
                ),
                const SizedBox(height: 24),
                _buildQuickActions(context),
                const SizedBox(height: 32),
                _buildUpcomingAppointments(appts),
                const SizedBox(height: 32),
                _buildRecentResults(batches),
                const SizedBox(height: 32),
                _buildPopularDoctors(doctorsState),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(user) {
    final userName = user?.fullName ?? 'Patient';
    final userEmail = user?.email ?? 'No email';
    final userPhone = user?.phone ?? '';
    final patientId = user?.userId.toString() ?? '';

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.80,
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(4, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 60),
            // Profile header
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryBlue.withValues(alpha: 0.3),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                      child: Icon(Icons.person, color: AppColors.primaryBlue, size: 44),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: AppTextStyles.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    userEmail,
                    style: AppTextStyles.bodyGrey,
                    textAlign: TextAlign.center,
                  ),
                  if (userPhone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      userPhone,
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (patientId.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'ID: $patientId',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, indent: 24, endIndent: 24),
            const SizedBox(height: 12),
            // Menu items
            _buildDrawerItem(
              icon: Icons.person_outline,
              label: 'My Profile',
              onTap: () => Navigator.pop(context),
            ),
            _buildDrawerItem(
              icon: Icons.folder_outlined,
              label: 'Medical Records',
              onTap: () => Navigator.pop(context),
            ),
            _buildDrawerItem(
              icon: Icons.calendar_today_outlined,
              label: 'Appointments',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () => Navigator.pop(context),
            ),
            const Spacer(),
            const Divider(height: 1, thickness: 1, indent: 24, endIndent: 24),
            const SizedBox(height: 8),
            _buildDrawerItem(
              icon: Icons.logout,
              label: 'Logout',
              color: AppColors.errorRed,
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog();
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final itemColor = color ?? AppColors.textDark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: itemColor, size: 22),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: itemColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(user, notifs) {
    return Row(
      children: [
        // Hamburger menu / drawer trigger
        GestureDetector(
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              shape: BoxShape.circle,
              boxShadow: AppTheme.cardShadow,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.menu_rounded,
                  color: AppColors.textDark,
                  size: 24,
                ),
                if (notifs.unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5252),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 2),
              Text(
                user?.fullName ?? 'Patient',
                style: AppTextStyles.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Notification bell
        _buildIconButton(
          icon: Icons.notifications_outlined,
          badge: notifs.unreadCount > 0,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    bool badge = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          shape: BoxShape.circle,
          boxShadow: AppTheme.cardShadow,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: AppColors.textDark, size: 20),
            if (badge)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5252),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.add_circle_outline,
            label: 'Book\nAppointment',
            color: AppColors.primaryBlue,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.description_outlined,
            label: 'My\nResults',
            color: const Color(0xFF7B1FA2),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyTestResultsScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingAppointments(appts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Upcoming Appointments', style: AppTextStyles.titleLarge),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
              ),
              child: Text(
                'View All',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (appts.upcoming.isEmpty)
          _buildEmptyState(
            Icons.event_available,
            'No upcoming appointments',
          )
        else ...[
          _buildFeaturedAppointmentCard(appts.upcoming.first),
          if (appts.upcoming.length > 1)
            ...appts.upcoming.skip(1).take(2).map(
              (a) => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _buildSimpleAppointmentCard(a),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildRecentResults(PatientBatchesState batches) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Recent Test Results', style: AppTextStyles.titleLarge),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyTestResultsScreen()),
              ),
              child: Text(
                'View All',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (batches.batches.isEmpty)
          _buildEmptyState(
            Icons.science_outlined,
            'No test results yet',
          )
        else
          ...batches.batches.take(3).map(
            (b) => Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildBatchCard(b),
            ),
          ),
      ],
    );
  }

  Widget _buildPopularDoctors(DoctorsState doctorsState) {
    final doctors = doctorsState.doctors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Popular Doctors', style: AppTextStyles.titleLarge),
            const Spacer(),
            GestureDetector(
              onTap: () {},
              child: Text(
                'View All',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 42,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            itemBuilder: (context, i) {
              final selected = i == _selectedFilter;
              return GestureDetector(
                onTap: () => setState(() => _selectedFilter = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: selected ? AppTheme.primaryGradient : null,
                    color: selected ? null : AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(21),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : AppColors.border,
                      width: 1.5,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppColors.primaryBlue.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : AppTheme.cardShadow,
                  ),
                  child: Center(
                    child: Text(
                      _filters[i],
                      style: GoogleFonts.poppins(
                        color: selected ? Colors.white : AppColors.textGrey,
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        if (doctorsState.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (doctors.isEmpty)
          _buildEmptyState(Icons.person_off_outlined, 'No doctors available')
        else
          () {
            final filtered = _selectedFilter == 0
                ? doctors
                : doctors.where((d) =>
                    d.specialization.toLowerCase() ==
                    _filters[_selectedFilter].toLowerCase()
                  ).toList();
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final doc = filtered[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryBlue.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                        child: Icon(Icons.person, color: AppColors.primaryBlue, size: 30),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.fullName,
                            style: AppTextStyles.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            doc.specialization.isNotEmpty ? doc.specialization : 'General',
                            style: AppTextStyles.bodyGrey,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          if (_pinnedDoctorIds.contains(doc.doctorId)) {
                            _pinnedDoctorIds.remove(doc.doctorId);
                          } else {
                            _pinnedDoctorIds.add(doc.doctorId);
                          }
                        });
                      },
                      icon: Icon(
                        _pinnedDoctorIds.contains(doc.doctorId)
                            ? Icons.push_pin
                            : Icons.push_pin_outlined,
                        color: _pinnedDoctorIds.contains(doc.doctorId)
                            ? AppColors.primaryBlue
                            : AppColors.textGrey,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              );
                },
              );
            }(),
      ],
    );
  }

  Widget _buildFeaturedAppointmentCard(appointment) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Icon(Icons.person, color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.doctorName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appointment.specialty ?? 'General Practice',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusBg(appointment.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  appointment.status.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _getStatusColor(appointment.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.white.withValues(alpha: 0.9), size: 16),
              const SizedBox(width: 6),
              Text(
                '${appointment.date.day}/${appointment.date.month}/${appointment.date.year}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(width: 20),
              Icon(Icons.access_time, color: Colors.white.withValues(alpha: 0.9), size: 16),
              const SizedBox(width: 6),
              Text(
                appointment.time,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleAppointmentCard(appointment) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.backgroundGrey,
            child: Icon(Icons.person, color: AppColors.primaryBlue, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.doctorName ?? 'Unknown Doctor',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '${appointment.date.day}/${appointment.date.month}  •  ${appointment.time}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusBg(appointment.status),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              appointment.status,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _getStatusColor(appointment.status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchCard(PatientBatch batch) {
    final dateStr = _formatBatchDate(batch.batchDate);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BatchDetailScreen(batch: batch),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.science, color: AppColors.primaryBlue, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateStr,
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${batch.resultCount} test${batch.resultCount == 1 ? '' : 's'}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }

  String _formatBatchDate(String? iso) {
    if (iso == null || iso.length < 10) return 'Unknown date';
    try {
      final parts = iso.substring(0, 10).split('-');
      if (parts.length != 3) return iso.substring(0, 10);
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final month = int.tryParse(parts[1]) ?? 0;
      return '${months[month]} ${parts[2]}, ${parts[0]}';
    } catch (_) {
      return iso.substring(0, 10);
    }
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      width: double.infinity,
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textGrey.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTextStyles.bodyGrey,
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
