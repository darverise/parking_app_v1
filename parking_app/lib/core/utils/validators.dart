// lib/core/utils/validators.dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Utility class for form validation
class Validators {
  /// Validates email using regex pattern
  static String? validateEmail(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) {
      return l10n.requiredField ?? 'This field is required';
    }
    final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegExp.hasMatch(value)) {
      return l10n.invalidEmail ?? 'Invalid email format';
    }
    return null;
  }

  /// Validates username
  static String? validateUsername(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) {
      return l10n.requiredField ?? 'This field is required';
    }
    if (value.length < 3) {
      // Using direct string fallback without relying on localization key
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  /// Validates password
  static String? validatePassword(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) {
      return l10n.requiredField ?? 'This field is required';
    }
    if (value.length < 6) {
      return l10n.passwordTooShort ?? 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validates that passwords match
  static String? validatePasswordMatch(
    BuildContext context,
    String? value,
    String password,
  ) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) {
      return l10n.requiredField ?? 'This field is required';
    }
    if (value != password) {
      // Using direct string fallback
      return 'Passwords do not match';
    }
    return null;
  }

  /// Generic validator for required fields
  static String? validateRequired(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) {
      return l10n.requiredField ?? 'This field is required';
    }
    return null;
  }

  /// Validates phone number format
  static String? validatePhone(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) {
      return l10n.requiredField ?? 'This field is required';
    }

    // Simple phone validation - can be enhanced for different regions
    final phoneRegExp = RegExp(r'^\d{10,15}$');
    if (!phoneRegExp.hasMatch(value.replaceAll(RegExp(r'[^0-9]'), ''))) {
      // Using direct string fallback
      return 'Invalid phone number';
    }
    return null;
  }
}
