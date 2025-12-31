import 'package:flutter/material.dart';

/// Kreo Calendar Color Palette
/// Premium design with deep purples, vibrant accents, and glassmorphism support
class AppColors {
  AppColors._();

  // Primary Colors - Deep Purple Theme
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFF9B8FF5);
  static const Color primaryDark = Color(0xFF4A3FC7);

  // Secondary Colors - Vibrant Accents
  static const Color secondary = Color(0xFF00D9FF);
  static const Color secondaryLight = Color(0xFF73E8FF);
  static const Color secondaryDark = Color(0xFF00A8C6);

  // Accent Colors
  static const Color accent = Color(0xFFFF6B9D);
  static const Color accentLight = Color(0xFFFF9EC4);
  static const Color accentDark = Color(0xFFD44A7A);

  // Success, Warning, Error
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFD93D);
  static const Color error = Color(0xFFFF5252);

  // Calendar Event Colors
  static const List<Color> eventColors = [
    Color(0xFF6C5CE7), // Purple
    Color(0xFF00D9FF), // Cyan
    Color(0xFFFF6B9D), // Pink
    Color(0xFF00E676), // Green
    Color(0xFFFFD93D), // Yellow
    Color(0xFFFF7675), // Coral
    Color(0xFF74B9FF), // Sky Blue
    Color(0xFFFDCB6E), // Orange
    Color(0xFFB8E994), // Mint
    Color(0xFFDDA0DD), // Plum
  ];

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF8F9FE);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF0F2F8);
  static const Color lightOnBackground = Color(0xFF1A1A2E);
  static const Color lightOnSurface = Color(0xFF2D2D44);
  static const Color lightOnSurfaceVariant = Color(0xFF6B6B8D);
  static const Color lightDivider = Color(0xFFE8EAF0);

  // Dark Theme Colors (OLED-friendly)
  static const Color darkBackground = Color(0xFF0A0A0F);
  static const Color darkSurface = Color(0xFF16161F);
  static const Color darkSurfaceVariant = Color(0xFF1E1E2D);
  static const Color darkOnBackground = Color(0xFFF5F5FF);
  static const Color darkOnSurface = Color(0xFFE8E8F0);
  static const Color darkOnSurfaceVariant = Color(0xFFA0A0B8);
  static const Color darkDivider = Color(0xFF2D2D3D);

  // Glassmorphism Colors
  static Color glassLight = Colors.white.withValues(alpha: 0.15);
  static Color glassDark = Colors.white.withValues(alpha: 0.08);
  static Color glassBorder = Colors.white.withValues(alpha: 0.2);

  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkBackgroundGradient = LinearGradient(
    colors: [Color(0xFF0A0A0F), Color(0xFF12121A), Color(0xFF1A1A28)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
