import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2979FF);   // Electric Blue
  static const Color secondary = Color(0xFFFF6D00); // Bright Orange
  static const Color accent = Color(0xFF00E676);    // Neon Green
  static const Color background = Color(0xFF121212); // Dark Background
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFBDBDBD); // Light Gray
}

final ThemeData appThemeDark = ThemeData(
  brightness: Brightness.dark,
  primaryColor: AppColors.primary,
  scaffoldBackgroundColor: AppColors.background,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.black,
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    iconTheme: IconThemeData(color: Colors.white),
  ),
  colorScheme: const ColorScheme.dark().copyWith(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 16),
    bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 14),
    titleLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
  ),
);
