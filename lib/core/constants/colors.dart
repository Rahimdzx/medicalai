import 'package:flutter/material.dart';

/// Application color palette
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFF63A4FF);
  static const Color primaryDark = Color(0xFF004BA0);

  // Secondary Colors
  static const Color secondary = Color(0xFF26A69A);
  static const Color secondaryLight = Color(0xFF64D8CB);
  static const Color secondaryDark = Color(0xFF00766C);

  // Accent Colors
  static const Color accent = Color(0xFF00BCD4);

  // Background Colors
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFE3F2FD);

  // Chat Colors
  static const Color chatBubbleSent = Color(0xFF1976D2);
  static const Color chatBubbleReceived = Color(0xFFE0E0E0);
  static const Color chatBubbleReceivedDark = Color(0xFF2C2C2C);

  // Call Colors
  static const Color callGreen = Color(0xFF4CAF50);
  static const Color callRed = Color(0xFFF44336);

  // Online Status
  static const Color online = Color(0xFF4CAF50);
  static const Color offline = Color(0xFF9E9E9E);
  static const Color busy = Color(0xFFF44336);
  static const Color away = Color(0xFFFF9800);

  // Specialization Colors (for doctor cards)
  static const Map<String, Color> specializationColors = {
    'general': Color(0xFF42A5F5),
    'cardiology': Color(0xFFEF5350),
    'dermatology': Color(0xFFAB47BC),
    'pediatrics': Color(0xFF66BB6A),
    'orthopedics': Color(0xFFFF7043),
    'neurology': Color(0xFF5C6BC0),
    'psychiatry': Color(0xFF26A69A),
    'dentistry': Color(0xFF78909C),
    'ophthalmology': Color(0xFF29B6F6),
  };

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryLight],
  );

  // Shadow Color
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowDark = Color(0x3D000000);

  // Divider Colors
  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF424242);

  // Shimmer Colors (for loading skeletons)
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color shimmerBaseDark = Color(0xFF424242);
  static const Color shimmerHighlightDark = Color(0xFF616161);
}
