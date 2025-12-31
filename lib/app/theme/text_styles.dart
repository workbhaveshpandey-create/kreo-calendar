import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kreo Calendar Text Styles
/// Modern typography using Outfit font family for premium feel
class AppTextStyles {
  AppTextStyles._();

  // Base font family - Outfit for modern, premium look
  static String get _fontFamily => GoogleFonts.outfit().fontFamily!;

  // Display styles
  static TextStyle displayLarge({Color? color}) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 57,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    color: color,
    height: 1.12,
  );

  static TextStyle displayMedium({Color? color}) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 45,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: color,
    height: 1.16,
  );

  static TextStyle displaySmall({Color? color}) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: color,
    height: 1.22,
  );

  // Headline styles
  static TextStyle headlineLarge({Color? color}) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: color,
    height: 1.25,
  );

  static TextStyle headlineMedium({Color? color}) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    color: color,
    height: 1.29,
  );

  static TextStyle headlineSmall({Color? color}) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    color: color,
    height: 1.33,
  );

  // Title styles
  static TextStyle titleLarge({Color? color}) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: color,
    height: 1.27,
  );

  static TextStyle titleMedium({Color? color}) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    color: color,
    height: 1.5,
  );

  static TextStyle titleSmall({Color? color}) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: color,
    height: 1.43,
  );

  // Body styles
  static TextStyle bodyLarge({Color? color}) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: color,
    height: 1.5,
  );

  static TextStyle bodyMedium({Color? color}) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    color: color,
    height: 1.43,
  );

  static TextStyle bodySmall({Color? color}) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: color,
    height: 1.33,
  );

  // Label styles
  static TextStyle labelLarge({Color? color}) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: color,
    height: 1.43,
  );

  static TextStyle labelMedium({Color? color}) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: color,
    height: 1.33,
  );

  static TextStyle labelSmall({Color? color}) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: color,
    height: 1.45,
  );

  // Calendar-specific styles
  static TextStyle calendarDay({Color? color}) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: color,
    height: 1,
  );

  static TextStyle calendarWeekday({Color? color}) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.0,
    color: color,
    height: 1,
  );

  static TextStyle calendarDaySelected({Color? color}) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: color ?? Colors.white,
    height: 1,
  );

  static TextStyle calendarMonth({Color? color}) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: 2.0,
    color: color,
    height: 1.4,
  );

  static TextStyle eventTitle({Color? color}) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: color ?? Colors.white,
    height: 1.3,
  );

  static TextStyle eventTime({Color? color}) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    color: color ?? Colors.white70,
    height: 1.2,
  );
}
