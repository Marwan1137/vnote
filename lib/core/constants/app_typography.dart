import 'package:flutter/material.dart';

class AppTypography {
  // Font Family (You can use default or Google Fonts)
  static const String fontFamily = 'Inter'; // Change to your Figma font

  // ==================== FONT SIZES ====================

  static const double size10 = 10.0;
  static const double size12 = 12.0;
  static const double size14 = 14.0;
  static const double size16 = 16.0;
  static const double size18 = 18.0;
  static const double size20 = 20.0;
  static const double size24 = 24.0;
  static const double size28 = 28.0;
  static const double size32 = 32.0;
  static const double size40 = 40.0;
  static const double size48 = 48.0;

  // ==================== FONT WEIGHTS ====================

  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;

  // ==================== LINE HEIGHTS ====================

  static const double lineHeight1 = 1.0;
  static const double lineHeight1_2 = 1.2;
  static const double lineHeight1_4 = 1.4;
  static const double lineHeight1_5 = 1.5;
  static const double lineHeight1_6 = 1.6;
  static const double lineHeight2 = 2.0;

  // ==================== LETTER SPACING ====================

  static const double letterSpacingTight = -0.5;
  static const double letterSpacingNormal = 0.0;
  static const double letterSpacingWide = 0.5;
  static const double letterSpacingWider = 1.0;

  // ==================== TEXT STYLES (Light Theme) ====================

  // Display Styles
  static const TextStyle displayLarge = TextStyle(
    fontSize: 48.0,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 40.0,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 32.0,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  // Heading Styles
  static const TextStyle h1 = TextStyle(
    fontSize: 32.0,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 28.0,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle h5 = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle h6 = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  // Body Styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // Label Styles
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10.0,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
  );

  // Caption Style
  static const TextStyle caption = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // Overline Style
  static const TextStyle overline = TextStyle(
    fontSize: 10.0,
    fontWeight: FontWeight.w500,
    height: 1.6,
    letterSpacing: 1.0,
  );

  // Button Styles
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: 0.5,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: 0.5,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: 0.5,
  );

  // Note Card Specific Styles (from Figma)
  static const TextStyle noteTitle = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle notePreview = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle noteTag = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    height: 1.0,
  );

  static const TextStyle noteTimestamp = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    height: 1.0,
  );
}
