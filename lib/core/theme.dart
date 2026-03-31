import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF020617);
  static const Color primary = Color(0xFF22C55E);
  static const Color primaryAccent = Color(0xFF22C55E); // Aliased
  static const Color cardBg = Color(0xFF0F172A);
  static const Color cardBackground = Color(0xFF0F172A); // Aliased
  static const Color secondaryCardBg = Color(0xFF1E293B);
  static const Color secondaryCard = Color(0xFF1E293B); // Aliased
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  
  static const Color liveBadge = Color(0xFFEF4444);
  static const Color upcomingBadge = Color(0xFF3B82F6);
  static const Color completedBadge = Color(0xFF6B7280);
  
  static const Color captainBadge = Color(0xFFF59E0B);
  static const Color vcBadge = Color(0xFFF87171); 
  static const Color silver = Color(0xFF94A3B8);
  
  static const Color shimmerBase = Color(0xFF1E293B);
  static const Color shimmerHighlight = Color(0xFF334155);
}

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primary,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      surface: AppColors.cardBackground,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    // Using CardTheme as valid ThemeData component
    cardTheme: const CardThemeData(
      color: AppColors.cardBackground,
      elevation: 2,
      margin: EdgeInsets.all(8),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textPrimary),
      bodySmall: TextStyle(color: AppColors.textSecondary),
    ),
  );
}
