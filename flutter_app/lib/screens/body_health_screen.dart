import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;
import '../providers/body_health_provider.dart';
import '../providers/auth_provider.dart';

class BodyHealthScreen extends ConsumerStatefulWidget {
  const BodyHealthScreen({super.key});

  @override
  ConsumerState<BodyHealthScreen> createState() => _BodyHealthScreenState();
}

class _BodyHealthScreenState extends ConsumerState<BodyHealthScreen> {
  String? _gender; // 'male' or 'female'
  double? _heightCm = 170;
  double? _weightKg = 70;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final patientId = ref.read(authProvider).patientId;
      if (patientId != null) {
        ref.read(bodyHealthProvider.notifier).load(patientId).then((_) {
          _populateFromProvider();
        });
      }
    });
  }

  void _populateFromProvider() {
    final data = ref.read(bodyHealthProvider);
    if (data != null) {
      setState(() {
        _gender = data.gender;
        _heightCm = data.heightCm ?? 170;
        _weightKg = data.weightKg ?? 70;
      });
    }
  }

  double? get _bmi {
    if (_heightCm == null || _weightKg == null || _heightCm == 0) return null;
    final h = _heightCm! / 100;
    return _weightKg! / (h * h);
  }

  String? get _bmiCategory {
    final b = _bmi;
    if (b == null) return null;
    if (b < 18.5) return 'Underweight';
    if (b < 25) return 'Normal';
    if (b < 30) return 'Overweight';
    return 'Obese';
  }

  int? get _calories {
    if (_weightKg == null || _weightKg == 0) return null;
    return (_weightKg! * 30).round();
  }

  bool get _isValid {
    return _gender != null &&
        _heightCm != null &&
        _weightKg != null &&
        _heightCm! > 50 &&
        _heightCm! < 300 &&
        _weightKg! > 20 &&
        _weightKg! < 700;
  }

  Future<void> _save() async {
    if (!_isValid) return;
    final patientId = ref.read(authProvider).patientId;
    if (patientId == null) return;

    setState(() => _isSaving = true);
    await ref.read(bodyHealthProvider.notifier).update(
      patientId,
      gender: _gender,
      heightCm: _heightCm,
      weightKg: _weightKg,
    );
    if (mounted) {
      setState(() {
        _isSaving = false;
        _hasChanges = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Body data saved!',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF00F5A0),
          duration: const Duration(seconds: 2),
        ),
      );
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bmi = _bmi;
    final category = _bmiCategory;
    final calories = _calories;

    return Scaffold(
      backgroundColor: const Color(0xFF021012),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Body Health',
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
            Text('Smart Body Analysis',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: const Color(0xFFAFC7C9))),
          ],
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              _buildGenderSelector(),
              const SizedBox(height: 20),
              if (_gender != null) _buildBodyVisualization(bmi, category),
              if (_gender != null) const SizedBox(height: 24),
              _buildInputCards(),
              const SizedBox(height: 16),
              if (_hasChanges)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isValid && !_isSaving ? _save : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          Colors.white.withValues(alpha: 0.1),
                      disabledForegroundColor:
                          Colors.white.withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Save Body Data',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
              const SizedBox(height: 20),
              _buildMetricCards(bmi, category, calories),
              const SizedBox(height: 20),
              _buildSummaryCard(bmi, category, calories),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: [
        Expanded(
          child: _GenderCard(
            label: 'Male',
            imagePath: 'assets/images/male.webp',
            isSelected: _gender == 'male',
            onTap: () => setState(() {
              _gender = 'male';
              _hasChanges = true;
            }),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GenderCard(
            label: 'Female',
            imagePath: 'assets/images/female.webp',
            isSelected: _gender == 'female',
            onTap: () => setState(() {
              _gender = 'female';
              _hasChanges = true;
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildBodyVisualization(double? bmi, String? category) {
    final imagePath = _gender == 'male'
        ? 'assets/images/male.png'
        : 'assets/images/female.png';

    return SizedBox(
      height: 420,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Large radial glow behind body
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1200),
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Container(
                width: 350,
                height: 420,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.6,
                    colors: [
                      const Color(0xFF00E5FF).withValues(alpha: 0.15),
                      const Color(0xFF00BCD4).withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Holographic ring effect
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 4),
            builder: (context, value, child) => Transform.rotate(
              angle: value * 2 * 3.14159,
              child: Container(
                width: 320,
                height: 420,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.06),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(160),
                ),
              ),
            ),
          ),
          // Floating body image with subtle animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            builder: (context, fadeValue, child) =>
                TweenAnimationBuilder<double>(
              tween: Tween(begin: -5.0, end: 5.0),
              duration: const Duration(seconds: 3),
              curve: Curves.easeInOut,
              builder: (context, floatValue, _) => Transform.translate(
                offset: Offset(0, fadeValue < 0.5 ? floatValue : -floatValue),
                child: Opacity(
                  opacity: fadeValue,
                  child: Container(
                    width: 280,
                    height: 400,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF)
                              .withValues(alpha: 0.2),
                          blurRadius: 60,
                          spreadRadius: 20,
                        ),
                        BoxShadow(
                          color: const Color(0xFF00BCD4)
                              .withValues(alpha: 0.15),
                          blurRadius: 100,
                          spreadRadius: 40,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.accessibility,
                        size: 180,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Scan line effect
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 3),
            builder: (context, value, child) => Positioned(
              top: 60 + value * 300,
              child: Container(
                width: 200,
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFF00E5FF).withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Category badge
          if (category != null)
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _categoryColor(category).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _categoryColor(category).withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _categoryColor(category).withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  category,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _categoryColor(category),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputCards() {
    return Row(
      children: [
        Expanded(
          child: _SelectionCard(
            label: 'Height',
            icon: Icons.height,
            value: _heightCm != null ? '${_heightCm!.round()} cm' : '--',
            onTap: () => _showPickerSheet(
              title: 'Select Height',
              min: 100,
              max: 230,
              value: _heightCm ?? 170,
              unit: 'cm',
              onChanged: (v) {
                setState(() {
                  _heightCm = v;
                  _hasChanges = true;
                });
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SelectionCard(
            label: 'Weight',
            icon: Icons.monitor_weight_outlined,
            value: _weightKg != null ? '${_weightKg!.round()} kg' : '--',
            onTap: () => _showPickerSheet(
              title: 'Select Weight',
              min: 30,
              max: 200,
              value: _weightKg ?? 70,
              unit: 'kg',
              onChanged: (v) {
                setState(() {
                  _weightKg = v;
                  _hasChanges = true;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showPickerSheet({
    required String title,
    required double min,
    required double max,
    required double value,
    required String unit,
    required Function(double) onChanged,
  }) {
    double tempValue = value;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0A1E22),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              // Large value display
              TweenAnimationBuilder<double>(
                tween: Tween(begin: min, end: tempValue),
                duration: const Duration(milliseconds: 100),
                builder: (context, v, _) => Text(
                  '${v.round()}',
                  style: GoogleFonts.poppins(
                    fontSize: 64,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF00E5FF),
                  ),
                ),
              ),
              Text(
                unit,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  color: const Color(0xFFAFC7C9),
                ),
              ),
              const SizedBox(height: 24),
              // Slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF00E5FF),
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                  thumbColor: const Color(0xFF00E5FF),
                  overlayColor:
                      const Color(0xFF00E5FF).withValues(alpha: 0.1),
                  valueIndicatorColor: const Color(0xFF00E5FF),
                  thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 12),
                  trackHeight: 4,
                ),
                child: Slider(
                  min: min,
                  max: max,
                  value: tempValue,
                  divisions: (max - min).round(),
                  label: '${tempValue.round()} $unit',
                  onChanged: (v) {
                    setSheetState(() => tempValue = v);
                    onChanged(v);
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Quick selection buttons
              Wrap(
                spacing: 8,
                children: unit == 'cm'
                    ? [140, 160, 170, 180, 190].map((v) {
                        return _QuickSelectButton(
                          value: '$v',
                          isSelected: tempValue.round() == v,
                          onTap: () {
                            setSheetState(() => tempValue = v.toDouble());
                            onChanged(v.toDouble());
                          },
                        );
                      }).toList()
                    : [50, 70, 80, 90, 100].map((v) {
                        return _QuickSelectButton(
                          value: '$v',
                          isSelected: tempValue.round() == v,
                          onTap: () {
                            setSheetState(() => tempValue = v.toDouble());
                            onChanged(v.toDouble());
                          },
                        );
                      }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Apply',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCards(double? bmi, String? category, int? calories) {
    return Row(
      children: [
        _MetricCard(
          label: 'Height',
          value: _heightCm != null ? '${_heightCm!.round()} cm' : '--',
          icon: Icons.height,
          color: const Color(0xFF00E5FF),
        ),
        const SizedBox(width: 12),
        _MetricCard(
          label: 'Weight',
          value: _weightKg != null ? '${_weightKg!.round()} kg' : '--',
          icon: Icons.monitor_weight_outlined,
          color: const Color(0xFF00F5A0),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(double? bmi, String? category, int? calories) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Health Summary',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _SummaryRow(
                label: 'BMI',
                value: bmi != null ? bmi.toStringAsFixed(1) : '--',
                sub: category ?? '',
                color: _categoryColor(category),
              ),
              const SizedBox(height: 12),
              _SummaryRow(
                label: 'Daily Calories',
                value: calories != null ? '$calories kcal/day' : '--',
                sub: 'Recommended intake',
                color: const Color(0xFF00F5A0),
              ),
              const SizedBox(height: 12),
              Text(
                _healthyRangeText(bmi),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFFAFC7C9),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _categoryColor(String? cat) {
    if (cat == 'Underweight') return const Color(0xFF00E5FF);
    if (cat == 'Normal') return const Color(0xFF00F5A0);
    if (cat == 'Overweight') return const Color(0xFFFFD166);
    if (cat == 'Obese') return const Color(0xFFFF5252);
    return const Color(0xFF00E5FF);
  }

  String _healthyRangeText(double? bmi) {
    if (bmi == null) return 'Select gender, height and weight to see recommendations.';
    if (bmi < 18.5) {
      return 'Your BMI is below normal range (18.5–24.9). Consider a nutrient-rich diet.';
    }
    if (bmi <= 24.9) {
      return 'Your BMI is in the healthy range (18.5–24.9). Maintain your current lifestyle!';
    }
    if (bmi <= 29.9) {
      return 'Your BMI is above normal range (18.5–24.9). Consider regular exercise and balanced diet.';
    }
    return 'Your BMI indicates obesity. Consult a healthcare provider for a personalized plan.';
  }
}

class _GenderCard extends StatelessWidget {
  final String label;
  final String imagePath;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.label,
    required this.imagePath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: isSelected
              ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF00E5FF).withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                    child: Image.asset(
                      imagePath,
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                      color: isSelected ? const Color(0xFF00E5FF) : Colors.white.withValues(alpha: 0.5),
                      errorBuilder: (_, __, ___) => Icon(
                        label == 'Male' ? Icons.man : Icons.woman,
                        color: isSelected ? const Color(0xFF00E5FF) : Colors.white.withValues(alpha: 0.5),
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? const Color(0xFF00E5FF) : Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: const Color(0xFF00E5FF), size: 20),
                      const Spacer(),
                      Icon(
                        Icons.edit,
                        color: Colors.white.withValues(alpha: 0.4),
                        size: 14,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFFAFC7C9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickSelectButton extends StatelessWidget {
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickSelectButton({
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00E5FF).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00E5FF).withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? const Color(0xFF00E5FF)
                : Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.12),
                  color.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFFAFC7C9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFAFC7C9)),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            sub,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
