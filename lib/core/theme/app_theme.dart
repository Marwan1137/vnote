// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:vnote/core/constants/app_colors.dart';
import 'package:vnote/core/constants/app_typography.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.red,
    scaffoldBackgroundColor: AppColors.lightGray,
    useMaterial3: true,

    colorScheme: const ColorScheme.light(
      primary: AppColors.red,
      secondary: AppColors.purple,
      surface: AppColors.white,
      surfaceContainerHighest: AppColors.white,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black,
      onError: Colors.white,
      outline: AppColors.gray,
      shadow: Color(0x1A000000),
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: AppTypography.size28,
        fontWeight: AppTypography.bold,
        color: Colors.black,
      ),
      bodyLarge: TextStyle(fontSize: AppTypography.size18, color: Colors.black),
      bodyMedium: TextStyle(
        fontSize: AppTypography.size16,
        color: Colors.black87,
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.gray.withOpacity(0.1), width: 1),
      ),
      color: AppColors.white,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),

    iconTheme: const IconThemeData(color: Colors.black87, size: 24),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.red,
      foregroundColor: Colors.white,
      elevation: 4,
      highlightElevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    dividerColor: AppColors.gray.withOpacity(0.1),
    splashColor: AppColors.red.withOpacity(0.1),
    highlightColor: AppColors.red.withOpacity(0.05),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.red,
    scaffoldBackgroundColor: AppColors.darkestGray,
    useMaterial3: true,

    colorScheme: const ColorScheme.dark(
      primary: AppColors.red,
      secondary: AppColors.purple,
      surface: AppColors.darkGray,
      surfaceContainerHighest: AppColors.darkGray,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.lightestGray,
      onError: Colors.white,
      outline: AppColors.lightestGray,
      shadow: Color(0x40000000),
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: AppTypography.size28,
        fontWeight: AppTypography.bold,
        color: AppColors.lightestGray,
      ),
      bodyLarge: TextStyle(
        fontSize: AppTypography.size18,
        color: AppColors.lightestGray,
      ),
      bodyMedium: TextStyle(
        fontSize: AppTypography.size16,
        color: AppColors.lightestGray,
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.lightestGray.withOpacity(0.1),
          width: 1,
        ),
      ),
      color: AppColors.darkGray,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkGray,
      foregroundColor: AppColors.lightestGray,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),

    iconTheme: const IconThemeData(color: AppColors.lightestGray, size: 24),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.red,
      foregroundColor: Colors.white,
      elevation: 4,
      highlightElevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    dividerColor: AppColors.lightestGray.withOpacity(0.1),
    splashColor: AppColors.red.withOpacity(0.2),
    highlightColor: AppColors.red.withOpacity(0.1),
  );
}
