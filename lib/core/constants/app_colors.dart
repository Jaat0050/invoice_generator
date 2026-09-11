import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Brand Colors - Modern Indigo / Deep Navy
  static const Color primary = Color(0xFF4F46E5); // Indigo 600
  static const Color primaryDark = Color(0xFF3730A3); // Indigo 800
  static const Color primaryLight = Color(0xFF818CF8); // Indigo 400
  static const Color primaryContainer = Color(0xFFEEF2FF); // Indigo 50

  // Secondary / Accent Colors - Vibrant Teal / Cyan
  static const Color secondary = Color(0xFF0EA5E9); // Sky 500
  static const Color secondaryLight = Color(0xFF38BDF8); // Sky 400
  static const Color secondaryContainer = Color(0xFFF0F9FF); // Sky 50

  // Accent Colors
  static const Color accent = Color(0xFF8B5CF6); // Violet 500
  static const Color accentGradientStart = Color(0xFF6366F1);
  static const Color accentGradientEnd = Color(0xFF4F46E5);

  // Status & Financial Indicators
  static const Color success = Color(0xFF10B981); // Emerald 500 - Paid
  static const Color successLight = Color(0xFFECFDF5);
  static const Color successDark = Color(0xFF047857);

  static const Color warning = Color(0xFFF59E0B); // Amber 500 - Partially Paid / Due soon
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color warningDark = Color(0xFFB45309);

  static const Color error = Color(0xFFEF4444); // Red 500 - Overdue / Cancelled
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color errorDark = Color(0xFFB91C1C);

  static const Color info = Color(0xFF3B82F6); // Blue 500 - Draft / Sent
  static const Color infoLight = Color(0xFFEFF6FF);

  // Neutrals (Light Mode)
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Slate 100
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color borderSubtle = Color(0xFFF1F5F9); // Slate 100

  // Text Colors (Light Mode)
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400
  static const Color textInverse = Color(0xFFFFFFFF);

  // Dark Mode Neutrals
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface = Color(0xFF1E293B); // Slate 800
  static const Color darkSurfaceVariant = Color(0xFF334155); // Slate 700
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x33FFFFFF),
      Color(0x0DFFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
