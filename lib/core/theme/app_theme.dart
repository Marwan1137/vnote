import 'package:flutter/material.dart';
import 'package:vnote/core/constants/app_colors.dart';
import 'package:vnote/core/constants/app_typography.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.red,
    scaffoldBackgroundColor: AppColors.white,

    colorScheme: const ColorScheme.light(
      primary: AppColors.red,
      secondary: AppColors.purple,
      surface: AppColors.white,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.darkBlue,
      onError: Colors.white,
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: AppTypography.size28,
        fontWeight: AppTypography.bold,
        color: AppColors.darkBlue,
      ),
      bodyLarge: TextStyle(
        fontSize: AppTypography.size18,
        color: AppColors.darkBlue,
      ),
      bodyMedium: TextStyle(
        fontSize: AppTypography.size16,
        color: AppColors.gray,
      ),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.darkBlue,
      elevation: 0,
    ),

    iconTheme: const IconThemeData(color: AppColors.darkBlue),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.red,
    scaffoldBackgroundColor: AppColors.darkestGray,

    colorScheme: const ColorScheme.dark(
      primary: AppColors.red,
      secondary: AppColors.purple,
      surface: AppColors.darkestGray,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.white,
      onError: Colors.white,
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: AppTypography.size28,
        fontWeight: AppTypography.bold,
        color: AppColors.white,
      ),
      bodyLarge: TextStyle(
        fontSize: AppTypography.size18,
        color: AppColors.white,
      ),
      bodyMedium: TextStyle(
        fontSize: AppTypography.size16,
        color: AppColors.lightestGray,
      ),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkGray,
      foregroundColor: AppColors.white,
      elevation: 0,
    ),

    iconTheme: const IconThemeData(color: AppColors.darkestGray),
  );
}
