import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette (from design requirements)
  static const Color primaryBlue = Color(0xFF4A7DFF);
  static const Color primaryLight = Color(0xFF6EA8FF);
  static const Color primaryDark = Color(0xFF3A6DEE);

  // Backgrounds
  static const Color backgroundGrey = Color(0xFFF5F7FB);
  static const Color cardWhite = Colors.white;

  // Text
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGrey = Color(0xFF7A7A7A);
  static const Color textHint = Color(0xFFB0BAC9);

  // Accents
  static const Color starGold = Color(0xFFFFB800);
  static const Color errorRed = Color(0xFFFF5252);

  // Status colors
  static const Color statusConfirmed = Color(0xFF00A86B);
  static const Color statusPending = Color(0xFFFFA000);
  static const Color statusCancelled = Color(0xFFD32F2F);
  static const Color statusConfirmedBg = Color(0xFFE8F5E9);
  static const Color statusPendingBg = Color(0xFFFFF3E0);
  static const Color statusCancelledBg = Color(0xFFFFEBEE);

  // Backward compatibility aliases
  static const Color textPrimary = textDark;
  static const Color textSecondary = textGrey;
  static const Color border = Color(0xFFE4EAF4);
  static const Color success = statusConfirmed;
  static const Color error = errorRed;
}
