import 'package:flutter/material.dart';

/// Centralized color palette for the E-BPCO User App.
///
/// All widgets should reference these constants instead of hardcoding
/// colors, so the visual identity stays consistent across the app.
class AppColors {
  AppColors._();

  // Brand / institutional colors.
  static const Color primaryNavy = Color(0xFF0B2545);
  static const Color primaryNavyDark = Color(0xFF071A33);
  static const Color secondaryBlue = Color(0xFF1E6FD9);
  static const Color lightBlue = Color(0xFFE8F1FC);

  // Backgrounds and surfaces.
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF5F7FA);
  static const Color border = Color(0xFFE1E5EB);

  // Text colors.
  static const Color textPrimary = Color(0xFF16213A);
  static const Color textSecondary = Color(0xFF5A6479);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF8A93A6);

  // Status colors.
  static const Color statusApproved = Color(0xFF1E8A4C);
  static const Color statusApprovedBg = Color(0xFFE6F5EB);
  static const Color statusPending = Color(0xFFB4740E);
  static const Color statusPendingBg = Color(0xFFFCF0DD);
  static const Color statusRejected = Color(0xFFC13B3B);
  static const Color statusRejectedBg = Color(0xFFFBEAEA);
  static const Color statusInfo = Color(0xFF1E6FD9);
  static const Color statusInfoBg = Color(0xFFE8F1FC);

  // Utility.
  static const Color divider = Color(0xFFE1E5EB);
  static const Color shadow = Color(0x1A0B2545);
  static const Color success = statusApproved;
  static const Color error = statusRejected;
  static const Color warning = statusPending;
}
