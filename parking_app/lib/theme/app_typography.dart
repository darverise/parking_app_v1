import 'package:flutter/material.dart';

/// Typography class to define all text styles used in the app
class AppTypography {
  // Font family name
  static const String fontFamily = 'NotoSansJP';
  static const String monospaceFontFamily =
      'NotoSansJP Mono'; // Or another monospace font you have

  // Text styles for headings
  static TextStyle get h1 => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.bold,
  );

  static TextStyle get h2 => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static TextStyle get h3 => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  // Text styles for body text
  static TextStyle get bodyLarge => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5, // Line height for better readability
  );

  static TextStyle get bodyMedium => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static TextStyle get bodySmall => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  // Button text style
  static TextStyle get button => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  // Caption text style
  static TextStyle get caption => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.normal,
  );

  // Monospace text styles with auto-adaptation
  static TextStyle get codeBlock => TextStyle(
    fontFamily: monospaceFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
    letterSpacing: 0,
    fontFeatures: const [
      FontFeature.tabularFigures(),
    ], // Equal width for numbers
  );

  static TextStyle get codeInline => TextStyle(
    fontFamily: monospaceFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  // Helper method to get text style that automatically adapts to device settings
  static TextStyle getAdaptiveStyle({
    required TextStyle baseStyle,
    bool allowFontScaling = true,
    double minFontSize = 8.0,
    double maxFontSize = 32.0,
  }) {
    return baseStyle.copyWith(
      fontSize: baseStyle.fontSize,
      fontFamily: baseStyle.fontFamily,
      height: baseStyle.height,
    );
  }
}
