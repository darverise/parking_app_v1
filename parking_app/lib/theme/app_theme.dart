import 'package:flutter/material.dart';
import 'package:parking_app/theme/app_colors.dart';
import 'package:parking_app/theme/text_styles.dart';
import 'package:parking_app/theme/app_typography.dart';

/// Class responsible for defining the app theme and styling
class AppTheme {
  /// Returns light theme configuration
  static ThemeData lightTheme() {
    return ThemeData(
      fontFamily: AppTypography.fontFamily,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.h1,
        displayMedium: AppTypography.h2,
        displaySmall: AppTypography.h3,
        headlineMedium: TextStyles.headlineMedium,
        headlineSmall: TextStyles.headlineSmall,
        titleLarge: TextStyles.titleLarge,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.button,
        labelSmall: AppTypography.caption,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 16.0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          minimumSize: const Size(double.infinity, 54),
          textStyle: TextStyles.buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: TextStyles.buttonText.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }

  /// Returns dark theme configuration
  static ThemeData darkTheme() {
    final darkTextTheme = TextTheme(
      displayLarge: AppTypography.h1.copyWith(color: Colors.white),
      displayMedium: AppTypography.h2.copyWith(color: Colors.white),
      displaySmall: AppTypography.h3.copyWith(color: Colors.white),
      headlineMedium: TextStyles.headlineMedium.copyWith(color: Colors.white),
      headlineSmall: TextStyles.headlineSmall.copyWith(color: Colors.white),
      titleLarge: TextStyles.titleLarge.copyWith(color: Colors.white),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: Colors.white),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: Colors.white),
      bodySmall: AppTypography.bodySmall.copyWith(color: Colors.white),
      labelLarge: AppTypography.button.copyWith(color: Colors.white),
      labelSmall: AppTypography.caption.copyWith(color: Colors.white),
    );

    return ThemeData.dark().copyWith(
      textTheme: darkTextTheme,
      primaryTextTheme: darkTextTheme,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface.withOpacity(0.8),
        error: AppColors.error,
      ),
      // Add other theme customization here
    );
  }
}
