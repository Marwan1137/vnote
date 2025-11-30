import 'package:flutter/material.dart';

class AppColors {
  // ==================== BRAND COLORS ====================

  // Primary Brand Color (Red Accent - from Splash)
  static const Color primaryRed = Color(0xFFFF6B6B); // Coral Red from mic icon
  static const Color primaryRedLight = Color(0xFFFF8E8E);
  static const Color primaryRedDark = Color(0xFFFF4848);

  // Accent Colors
  static const Color accentPurple = Color(0xFF6C63FF);
  static const Color accentBlue = Color(0xFF4A90E2);

  // ==================== LIGHT THEME COLORS ====================

  // Backgrounds
  static const Color lightBackground = Color(0xFFF5F7FA); // Light gray-blue
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure white
  static const Color lightCardBackground = Color(0xFFFFFFFF);

  // Text Colors
  static const Color lightTextPrimary = Color(0xFF1A1A1A); // Almost black
  static const Color lightTextSecondary = Color(0xFF666666); // Medium gray
  static const Color lightTextTertiary = Color(0xFF999999); // Light gray
  static const Color lightTextDisabled = Color(0xFFCCCCCC);

  // Border & Divider
  static const Color lightBorder = Color(0xFFE5E5E5);
  static const Color lightDivider = Color(0xFFEEEEEE);

  // Input Fields
  static const Color lightInputBackground = Color(0xFFF8F9FA);
  static const Color lightInputBorder = Color(0xFFE0E0E0);
  static const Color lightInputFocused = Color(0xFF6C63FF);

  // Category Border Colors (from note cards)
  static const Color categoryBlue = Color(0xFF4A90E2);
  static const Color categoryGreen = Color(0xFF4CAF50);
  static const Color categoryPurple = Color(0xFF9C27B0);
  static const Color categoryOrange = Color(0xFFFF9800);
  static const Color categoryPink = Color(0xFFE91E63);

  // ==================== DARK THEME COLORS ====================

  // Backgrounds
  static const Color darkBackground = Color(0xFF0F1419); // Very dark blue-gray
  static const Color darkSurface = Color(0xFF1A1F29); // Dark blue-gray
  static const Color darkCardBackground = Color(0xFF232834); // Slightly lighter

  // Text Colors
  static const Color darkTextPrimary = Color(0xFFFFFFFF); // Pure white
  static const Color darkTextSecondary = Color(0xFFB0B8C1); // Light gray
  static const Color darkTextTertiary = Color(0xFF8A92A0); // Medium gray
  static const Color darkTextDisabled = Color(0xFF5A5F6B);

  // Border & Divider
  static const Color darkBorder = Color(0xFF2D3340);
  static const Color darkDivider = Color(0xFF252A35);

  // Input Fields
  static const Color darkInputBackground = Color(0xFF1E2430);
  static const Color darkInputBorder = Color(0xFF2D3340);
  static const Color darkInputFocused = Color(0xFF6C63FF);

  // ==================== SEMANTIC COLORS ====================

  // Success
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  static const Color successDark = Color(0xFF388E3C);

  // Error
  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFE57373);
  static const Color errorDark = Color(0xFFD32F2F);

  // Warning
  static const Color warning = Color(0xFFFFC107);
  static const Color warningLight = Color(0xFFFFD54F);
  static const Color warningDark = Color(0xFFFFA000);

  // Info
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFF64B5F6);
  static const Color infoDark = Color(0xFF1976D2);

  // ==================== RECORDING COLORS ====================

  static const Color recordingActive = Color(0xFFFF6B6B); // Red accent
  static const Color recordingPaused = Color(0xFFFFC107); // Yellow
  static const Color recordingWaveform = Color(0xFFFF6B6B);
  static const Color recordingBackground = Color(
    0xFF000000,
  ); // Pure black for recording screen

  // ==================== TAG COLORS ====================

  static const Color tagWork = Color(0xFF4A90E2);
  static const Color tagPersonal = Color(0xFF4CAF50);
  static const Color tagIdeas = Color(0xFF9C27B0);
  static const Color tagMeeting = Color(0xFFFF9800);
  static const Color tagCooking = Color(0xFFE91E63);
  static const Color tagAI = Color(0xFF6C63FF);

  // ==================== TRANSPARENT OVERLAYS ====================

  static const Color overlayLight = Color(0x0D000000); // 5% black
  static const Color overlayMedium = Color(0x1A000000); // 10% black
  static const Color overlayDark = Color(0x80000000); // 50% black

  // ==================== GRADIENTS ====================

  static const List<Color> primaryGradient = [
    Color(0xFFFF6B6B),
    Color(0xFFFF8E8E),
  ];

  static const List<Color> accentGradient = [
    Color(0xFF6C63FF),
    Color(0xFF9D97FF),
  ];

  static const List<Color> darkGradient = [
    Color(0xFF0F1419),
    Color(0xFF1A1F29),
  ];
}
