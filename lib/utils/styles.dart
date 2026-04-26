import 'package:flutter/material.dart';

class AppColors {
  // Theme Light (Auth)
  static const Color authBgStart = Color(0xFFF8FAFC);
  static const Color authBgEnd = Color(0xFFE2E8F0);
  static const Color authText = Color(0xFF0F172A);
  static const Color authTextMuted = Color(0xFF64748B);
  
  // Roles
  static const Color customer = Color(0xFFF97316); // Orange hsl(26, 95%, 55%)
  static const Color employee = Color(0xFF16A34A); // Green hsl(142, 71%, 40%)
  
  // Dashboard Dark (matching he-header background)
  static const Color dashboardBg = Color(0xFF16171D);
  static const Color dashboardHeader = Color(0xFF0D0E12); // hsla(220, 20%, 6%, 0.85)
  static const Color glassBg = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  
  static const Color primary = employee;
  static const Color accent = employee;
  static const Color text = Color(0xFFF3F4F6);
  static const Color textMuted = Color(0xFF9CA3AF);
}

class AppStyles {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.authBgStart,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: AppColors.authText,
        letterSpacing: -1,
      ),
      bodyMedium: TextStyle(
        color: AppColors.authTextMuted,
        fontSize: 14,
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.dashboardBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.dashboardHeader,
      elevation: 0,
      centerTitle: false,
    ),
    // ...
  );
}
