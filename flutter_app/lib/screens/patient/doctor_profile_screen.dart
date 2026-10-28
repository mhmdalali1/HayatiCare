import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/doctor_avatars.dart';

class DoctorProfileScreen extends StatefulWidget {
  final String doctorName;
  final String specialization;
  final double rating;
  final int reviewCount;
  final int doctorIndex;

  const DoctorProfileScreen({
    super.key,
    this.doctorName = 'Dr. Sarah Johnson',
    this.specialization = 'Cardiologist',
    this.rating = 4.9,
    this.reviewCount = 128,
    this.doctorIndex = 0,
  });

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  int _selectedDateIndex = 0;
  int _selectedTimeIndex = -1;
  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static const _timeSlots = [
    '09:00 AM', '09:30 AM', '10:00 AM',
    '10:30 AM', '11:00 AM', '11:30 AM',
    '02:00 PM', '02:30 PM',
  ];

  List<int> _getDatesForMonth() {
    return List.generate(
      DateUtils.getDaysInMonth(_currentYear, _currentMonth),
      (i) => i + 1,
    );
  }

  void _prevMonth() {
    setState(() {
      if (_currentMonth == 1) {
        _currentMonth = 12;
        _currentYear--;
      } else {
        _currentMonth--;
      }
      _selectedDateIndex = 0;
      _selectedTimeIndex = -1;
    });
  }

  void _nextMonth() {
    setState(() {
      if (_currentMonth == 12) {
        _currentMonth = 1;
        _currentYear++;
      } else {
        _currentMonth++;
      }
      _selectedDateIndex = 0;
      _selectedTimeIndex = -1;
    });
  }

  void _onDateSelect(int index) {
    setState(() {
      _selectedDateIndex = index;
      _selectedTimeIndex = -1;
    });
  }

  void _onTimeSelect(int index) {
    setState(() => _selectedTimeIndex = index);
  }

  void _onBookingPressed() {
    if (_selectedTimeIndex < 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Appointment booked for ${_timeSlots[_selectedTimeIndex]}',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dates = _getDatesForMonth();

    return Scaffold(
      backgroundColor: AppColors.cardWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.textDark),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroSection(context),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        _buildSelectDateHeader(),
                        const SizedBox(height: 12),
                        _buildDatePicker(dates),
                        const SizedBox(height: 24),
                        _buildSelectTimeHeader(),
                        const SizedBox(height: 12),
                        _buildTimeGrid(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 280,
          width: double.infinity,
          color: AppColors.backgroundGrey,
        ),
        Positioned(
          right: 0,
          top: 0,
          child: CachedNetworkImage(
            imageUrl: DoctorAvatars.getAvatar(widget.doctorIndex),
            width: 220,
            height: 280,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 220,
              height: 280,
              color: AppColors.backgroundGrey,
              child: const Center(
                child: Icon(Icons.person, size: 80, color: AppColors.textGrey),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              width: 220,
              height: 280,
              color: AppColors.backgroundGrey,
              child: const Center(
                child: Icon(Icons.person, size: 80, color: AppColors.textGrey),
              ),
            ),
          ),
        ),
        Positioned(
          left: 20,
          top: 16,
          child: Row(
            children: [
              const Icon(Icons.star, color: AppColors.starGold, size: 18),
              const SizedBox(width: 4),
              Text(
                widget.rating.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 20,
          bottom: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.doctorName, style: AppTextStyles.heading1),
              const SizedBox(height: 4),
              Text(widget.specialization, style: AppTextStyles.subtitle),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectDateHeader() {
    return Row(
      children: [
        Text('Select Date', style: AppTextStyles.titleMedium),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.textDark),
          onPressed: _prevMonth,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 4),
        Text(
          '${_months[_currentMonth - 1]} $_currentYear',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: AppColors.textDark),
          onPressed: _nextMonth,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildDatePicker(List<int> dates) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        itemBuilder: (context, i) {
          final isSelected = i == _selectedDateIndex;
          final dayName = _dayNames[i % 7];
          return GestureDetector(
            onTap: () => _onDateSelect(i),
            child: Container(
              width: 56,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBlue : AppColors.cardWhite,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppColors.primaryBlue.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textGrey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${dates[i]}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectTimeHeader() {
    return Row(
      children: [
        Text('Select Time', style: AppTextStyles.titleMedium),
        const Spacer(),
        const Icon(Icons.chevron_left, color: AppColors.textGrey, size: 20),
        const SizedBox(width: 4),
        Text(
          '${_timeSlots.length} Slots',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right, color: AppColors.textGrey, size: 20),
      ],
    );
  }

  Widget _buildTimeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _timeSlots.length,
      itemBuilder: (context, i) {
        final isSelected = i == _selectedTimeIndex;
        return GestureDetector(
          onTap: () => _onTimeSelect(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryBlue : AppColors.cardWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primaryBlue : AppColors.backgroundGrey,
              ),
            ),
            child: Center(
              child: Text(
                _timeSlots[i],
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textDark,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return BottomAppBar(
      color: AppColors.cardWhite,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: AppColors.backgroundGrey,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryBlue),
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _selectedTimeIndex >= 0 ? _onBookingPressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  disabledBackgroundColor: AppColors.backgroundGrey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: Text('Book an Appointment', style: AppTextStyles.buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
