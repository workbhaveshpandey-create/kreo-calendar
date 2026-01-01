import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kreo Calendar - Dark Navy Theme
/// Matching the premium dark calendar design
class AppColors {
  AppColors._();

  // Primary Navy Colors
  // Primary Navy Colors
  static const Color primaryLight = Color(0xFF8B83FF);
  static const Color primaryDark = Color(0xFF5046E5);

  // Gradient helper
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Accent Colors
  static const Color accentGreen = Color(0xFF4ECDC4); // Teal/Cyan for events
  static const Color accentOrange = Color(0xFFFFB347); // Orange

  // Semantic Colors
  static const Color success = Color(0xFF4ECDC4);
  static const Color warning = Color(0xFFFFB347);
  static const Color error = Color(0xFFFF6B6B);

  // Divider & variants
  static const Color divider = Color(0xFF2D3E50);
  static const Color onSurfaceVariant = Color(0xFF8899A6);

  // Light Theme (Fallback)
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Colors.white;
  static const Color lightSurfaceVariant = Color(0xFFE8ECF0);
  static const Color lightOnBackground = Color(0xFF1A1A2E);
  static const Color lightOnSurface = Color(0xFF1A1A2E);
  static const Color lightOnSurfaceVariant = Color(0xFF6B7280);
  static const Color lightDivider = Color(0xFFE5E7EB);

  // Event Colors - Monochromatic / Subtle accents
  static const List<Color> eventColors = [
    Color(0xFFFFFFFF), // White
    Color(0xFFB0B0B0), // Light Grey
    Color(0xFF808080), // Grey
    Color(0xFF404040), // Dark Grey
    Color(0xFFE0E0E0), // Off White
  ];

  // Minimalist Future Colors
  static const Color minimalBlack = Color(0xFF000000);
  static const Color minimalSurface = Color(0xFF101010);
  static const Color minimalWhite = Color(0xFFFFFFFF);
  static const Color minimalAccent = Color(0xFFFFFFFF);
  static const Color minimalError = Color(0xFFFF3B30);

  // Override standard theme colors with minimalist ones
  static const Color background = minimalBlack;
  static const Color surface = minimalSurface;
  static const Color surfaceVariant = Color(0xFF202020);
  static const Color onBackground = minimalWhite;
  static const Color onSurface = minimalWhite;
  static const Color primary =
      minimalWhite; // Primary is white for high contrast
  static const Color accent = minimalWhite;

  static const LinearGradient cyberGradient = LinearGradient(
    colors: [Colors.black, Color(0xFF1A1A1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Futuristic / Cyberpunk Accents
  static const Color neonCyan = Color(0xFF00F0FF);
  static const Color neonPurple = Color(0xFFBC13FE);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassSurface = Color(0x1AFFFFFF);

  // Gradient for backgrounds
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0D1B2A), Color(0xFF1B2838)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Dark Theme Only
  static const Color darkBackground = background;
  static const Color darkSurface = surface;
  static const Color darkSurfaceVariant = surfaceVariant;
  static const Color darkOnBackground = onBackground;
  static const Color darkOnSurface = onSurface;
  static const Color darkOnSurfaceVariant = onSurfaceVariant;
  static const Color darkDivider = divider;
}

/// Clean Typography using Poppins
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _poppins({
    required double size,
    FontWeight weight = FontWeight.normal,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // Display
  static TextStyle displayLarge({Color? color}) => _poppins(
    size: 42,
    weight: FontWeight.w600,
    color: color,
    letterSpacing: -1.0,
  );
  static TextStyle displayMedium({Color? color}) => _poppins(
    size: 32,
    weight: FontWeight.w600,
    color: color,
    letterSpacing: -0.5,
  );
  static TextStyle displaySmall({Color? color}) =>
      _poppins(size: 24, weight: FontWeight.w500, color: color);

  // Headlines
  static TextStyle headlineLarge({Color? color}) =>
      _poppins(size: 22, weight: FontWeight.w600, color: color);
  static TextStyle headlineMedium({Color? color}) =>
      _poppins(size: 18, weight: FontWeight.w600, color: color);
  static TextStyle headlineSmall({Color? color}) =>
      _poppins(size: 16, weight: FontWeight.w600, color: color);

  // Titles
  static TextStyle titleLarge({Color? color}) =>
      _poppins(size: 17, weight: FontWeight.w500, color: color);
  static TextStyle titleMedium({Color? color}) =>
      _poppins(size: 15, weight: FontWeight.w500, color: color);
  static TextStyle titleSmall({Color? color}) =>
      _poppins(size: 13, weight: FontWeight.w500, color: color);

  // Body
  static TextStyle bodyLarge({Color? color}) =>
      _poppins(size: 15, weight: FontWeight.w400, color: color, height: 1.5);
  static TextStyle bodyMedium({Color? color}) =>
      _poppins(size: 14, weight: FontWeight.w400, color: color, height: 1.5);
  static TextStyle bodySmall({Color? color}) =>
      _poppins(size: 12, weight: FontWeight.w400, color: color, height: 1.4);

  // Labels
  static TextStyle labelLarge({Color? color}) =>
      _poppins(size: 14, weight: FontWeight.w500, color: color);
  static TextStyle labelMedium({Color? color}) =>
      _poppins(size: 12, weight: FontWeight.w500, color: color);
  static TextStyle labelSmall({Color? color}) => _poppins(
    size: 10,
    weight: FontWeight.w500,
    color: color,
    letterSpacing: 0.5,
  );

  // Calendar Specific
  static TextStyle calendarDay({Color? color}) =>
      _poppins(size: 14, weight: FontWeight.w500, color: color);
  static TextStyle calendarDaySelected() =>
      _poppins(size: 14, weight: FontWeight.w600, color: Colors.white);
  static TextStyle calendarMonth({Color? color}) =>
      _poppins(size: 20, weight: FontWeight.w600, color: color);
  static TextStyle calendarWeekday({Color? color}) =>
      _poppins(size: 11, weight: FontWeight.w500, color: color);
}

/// Dark Navy Theme Configuration
class AppTheme {
  AppTheme._();

  // Proper Light Theme
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: Colors.black,
    scaffoldBackgroundColor: AppColors.lightBackground,
    colorScheme: const ColorScheme.light(
      primary: Colors.black,
      secondary: Colors.black87,
      surface: Colors.white,
      surfaceContainerHighest: AppColors.lightSurfaceVariant,
      error: AppColors.minimalError,
      onSurface: Colors.black,
      onSurfaceVariant: AppColors.lightOnSurfaceVariant,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.lightBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: AppTextStyles.titleLarge(color: Colors.black),
      iconTheme: const IconThemeData(color: Colors.black),
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    dividerTheme: DividerThemeData(
      color: Colors.black.withOpacity(0.1),
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.transparent,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Colors.black.withOpacity(0.2)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Colors.black, width: 1),
      ),
      hintStyle: AppTextStyles.bodyMedium(color: Colors.grey),
    ),
    textTheme: TextTheme(
      bodyMedium: AppTextStyles.bodyMedium(color: Colors.black),
      bodySmall: AppTextStyles.bodySmall(color: Colors.grey),
      titleMedium: AppTextStyles.titleMedium(color: Colors.black),
      headlineSmall: AppTextStyles.headlineSmall(color: Colors.black),
      headlineMedium: AppTextStyles.headlineMedium(color: Colors.black),
    ),
    // Time Picker Theme - Light styling
    timePickerTheme: TimePickerThemeData(
      backgroundColor: Colors.white,
      hourMinuteColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.grey[200]!;
        }
        return Colors.grey[100]!;
      }),
      hourMinuteTextColor: WidgetStateColor.resolveWith(
        (states) => Colors.black,
      ),
      dialBackgroundColor: Colors.grey[100],
      dialHandColor: Colors.black,
      dialTextColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return Colors.black;
      }),
      entryModeIconColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      cancelButtonStyle: TextButton.styleFrom(foregroundColor: Colors.black54),
      confirmButtonStyle: TextButton.styleFrom(foregroundColor: Colors.black),
    ),
    // Date Picker Theme - Light styling
    datePickerTheme: DatePickerThemeData(
      backgroundColor: Colors.white,
      headerBackgroundColor: Colors.grey[100],
      headerForegroundColor: Colors.black,
      surfaceTintColor: Colors.transparent,
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return Colors.black;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.black;
        }
        return Colors.transparent;
      }),
      todayForegroundColor: WidgetStateProperty.all(Colors.black),
      todayBorder: const BorderSide(color: Colors.black),
      yearForegroundColor: WidgetStateProperty.all(Colors.black),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      cancelButtonStyle: TextButton.styleFrom(foregroundColor: Colors.black54),
      confirmButtonStyle: TextButton.styleFrom(foregroundColor: Colors.black),
    ),
    // Dialog Theme
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: Colors.white,
    scaffoldBackgroundColor: AppColors.minimalBlack,
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      secondary: Colors.white,
      surface: AppColors.minimalBlack,
      surfaceContainerHighest: Color(0xFF202020), // Replaces surfaceVariant
      error: AppColors.minimalError,
      onSurface: Colors.white,
      onSurfaceVariant: Colors.grey,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.minimalBlack,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: AppTextStyles.titleLarge(color: Colors.white),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    cardTheme: const CardThemeData(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(color: Colors.white24, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.transparent,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Colors.white24),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Colors.white, width: 1),
      ),
      hintStyle: AppTextStyles.bodyMedium(color: Colors.grey),
    ),
    textTheme: TextTheme(
      bodyMedium: AppTextStyles.bodyMedium(color: Colors.white),
      bodySmall: AppTextStyles.bodySmall(color: Colors.grey),
      titleMedium: AppTextStyles.titleMedium(color: Colors.white),
      headlineSmall: AppTextStyles.headlineSmall(color: Colors.white),
      headlineMedium: AppTextStyles.headlineMedium(color: Colors.white),
    ),
    // Time Picker Theme - Dark styling
    timePickerTheme: TimePickerThemeData(
      backgroundColor: const Color(0xFF1A1A1A),
      hourMinuteColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF3A3A3A); // Slightly lighter when selected
        }
        return const Color(0xFF2A2A2A);
      }),
      hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
        return Colors.white;
      }),
      dayPeriodColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF3A3A3A);
        }
        return const Color(0xFF2A2A2A);
      }),
      dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
        return Colors.white;
      }),
      dialBackgroundColor: const Color(0xFF2A2A2A),
      dialHandColor: Colors.white,
      dialTextColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.black;
        }
        return Colors.white;
      }),
      entryModeIconColor: Colors.white,
      helpTextStyle: GoogleFonts.outfit(
        color: Colors.white70,
        fontSize: 12,
        letterSpacing: 1,
      ),
      hourMinuteTextStyle: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 48,
        fontWeight: FontWeight.w300,
      ),
      dayPeriodTextStyle: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      dayPeriodShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.white24),
      ),
      hourMinuteShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      cancelButtonStyle: TextButton.styleFrom(foregroundColor: Colors.white70),
      confirmButtonStyle: TextButton.styleFrom(foregroundColor: Colors.white),
    ),
    // Date Picker Theme - Dark styling
    datePickerTheme: DatePickerThemeData(
      backgroundColor: const Color(0xFF1A1A1A),
      headerBackgroundColor: Colors.black,
      headerForegroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.black;
        }
        return Colors.white;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return Colors.transparent;
      }),
      todayForegroundColor: WidgetStateProperty.all(Colors.white),
      todayBorder: const BorderSide(color: Colors.white),
      yearForegroundColor: WidgetStateProperty.all(Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      cancelButtonStyle: TextButton.styleFrom(foregroundColor: Colors.white70),
      confirmButtonStyle: TextButton.styleFrom(foregroundColor: Colors.white),
    ),
    // Dialog Theme
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF1A1A1A),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
