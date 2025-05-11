import 'package:flutter/material.dart';
import 'package:parking_app/theme/app_colors.dart';

class TextStyles {
  static const String _fontFamily = 'Roboto';

  // Display styles
  static final TextStyle displayLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 57.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static final TextStyle displayMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 45.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static final TextStyle displaySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 36.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  // Headline styles
  static final TextStyle headlineMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static final TextStyle headlineSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  // Title styles
  static final TextStyle titleLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  // 添加缺失的titleMedium
  static final TextStyle titleMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  // 添加缺失的titleSmall
  static final TextStyle titleSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  // Body styles
  static final TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static final TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  // 添加缺失的bodySmall
  static final TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  // Button text style
  static final TextStyle buttonText = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  // Input field text styles
  static final TextStyle inputText = bodyLarge;
  static final TextStyle inputLabel = bodyMedium.copyWith(
    color: AppColors.textSecondary,
  );
  static final TextStyle inputHint = bodyMedium.copyWith(
    color: AppColors.textHint,
  );

  // Dialog text styles
  static const TextStyle dialogTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle dialogBody = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle dialogLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
}
