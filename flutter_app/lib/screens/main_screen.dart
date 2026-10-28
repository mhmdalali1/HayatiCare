import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/notifications_provider.dart';
import '../core/constants/app_colors.dart';
import 'dashboard_screen.dart';
import 'appointments_screen.dart';
import 'body_health_screen.dart';
import 'chatbot_screen.dart';
import 'notifications_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late PageController _pageController;
  late AnimationController _bubbleAnimController;

  final _screens = const [
    DashboardScreen(),
    AppointmentsScreen(),
    BodyHealthScreen(),
    ChatbotScreen(),
    NotificationsScreen(),
  ];

  static const _navItems = [
    _NavItemData(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    _NavItemData(
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today,
        label: 'Appts'),
    _NavItemData(
        icon: Icons.monitor_weight_outlined,
        activeIcon: Icons.monitor_weight,
        label: 'Body'),
    _NavItemData(
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble,
        label: 'AI'),
    _NavItemData(
        icon: Icons.notifications_outlined,
        activeIcon: Icons.notifications,
        label: 'Alerts'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _bubbleAnimController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _bubbleAnimController.forward();
    Future.microtask(
        () => ref.read(notificationsProvider.notifier).load());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bubbleAnimController.dispose();
    super.dispose();
  }

  void _onTabTap(int i) {
    if (_index == i) return;
    setState(() => _index = i);
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _bubbleAnimController.reset();
    _bubbleAnimController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final navWidth = screenWidth - 32;
    final itemWidth = navWidth / _navItems.length;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) {
          setState(() => _index = i);
          _bubbleAnimController.reset();
          _bubbleAnimController.forward();
        },
        children: _screens,
      ),
      extendBody: true,
      bottomNavigationBar: _buildBottomNav(itemWidth),
    );
  }

  Widget _buildBottomNav(double itemWidth) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      height: 76,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Frosted glass background
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(38),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.65),
                        Colors.white.withValues(alpha: 0.45),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(38),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Transparent water-droplet indicator
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.linear,
            bottom: 10,
            left: (itemWidth * _index) + (itemWidth - 58) / 2,
            child: AnimatedBuilder(
              animation: _bubbleAnimController,
              builder: (context, child) {
                final t = _bubbleAnimController.value;
                return Opacity(
                  opacity: t,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Soft blue glow around the droplet
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(
                              alpha: 0.08 * t),
                          blurRadius: 28,
                          offset: Offset.zero,
                          spreadRadius: 10,
                        ),
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(
                              alpha: 0.12 * t),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                          spreadRadius: 2,
                        ),
                        // Floating shadow below
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06 * t),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            // Water tint — very light blue transparent
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.55),
                                AppColors.primaryBlue.withValues(alpha: 0.12),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.65),
                              width: 1.8,
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Specular highlight — the "shine" on the water droplet
                              Positioned(
                                top: 8,
                                left: 10,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      center: Alignment.center,
                                      radius: 0.5,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.85),
                                        Colors.white.withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Secondary smaller highlight
                              Positioned(
                                top: 16,
                                left: 20,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                              // Refraction edge glow
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    center: Alignment.center,
                                    radius: 0.9,
                                    colors: [
                                      Colors.transparent,
                                      AppColors.primaryBlue.withValues(alpha: 0.06),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Navigation items
          SizedBox(
            height: 72,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                final isSelected = _index == i;
                return GestureDetector(
                  onTap: () => _onTabTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: itemWidth,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                          child: Icon(
                            isSelected ? item.activeIcon : item.icon,
                            key: ValueKey(isSelected),
                            color: isSelected
                                ? AppColors.primaryBlue
                                : AppColors.textGrey,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? AppColors.primaryBlue
                                : AppColors.textGrey,
                          ),
                          child: Text(item.label),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
