// lib/core/utils/localization_helper.dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Helper class for handling localization strings
/// This provides a fallback mechanism when localization keys are missing
class LocalizationHelper {
  /// Get a localized string with fallback
  static String getString(
    BuildContext context,
    String Function(AppLocalizations?) localizedStringGetter,
    String fallbackString,
  ) {
    final l10n = AppLocalizations.of(context);
    try {
      final localizedString = localizedStringGetter(l10n);
      if (localizedString.isNotEmpty) {
        return localizedString;
      }
    } catch (e) {
      // If the key doesn't exist or any other error occurs,
      // we'll return the fallback string
    }
    return fallbackString;
  }

  /// Common validation messages
  static String getRequiredFieldMessage(BuildContext context) {
    return getString(
      context,
      (l10n) => l10n?.requiredField ?? '',
      'This field is required',
    );
  }

  static String getInvalidEmailMessage(BuildContext context) {
    return getString(
      context,
      (l10n) => l10n?.invalidEmail ?? '',
      'Please enter a valid email address',
    );
  }

  static String getPasswordTooShortMessage(BuildContext context) {
    return getString(
      context,
      (l10n) => l10n?.passwordTooShort ?? '',
      'Password must be at least 6 characters',
    );
  }

  static String getUsernameTooShortMessage(BuildContext context) {
    return 'Username must be at least 3 characters';
  }

  static String getPasswordsDoNotMatchMessage(BuildContext context) {
    return 'Passwords do not match';
  }

  static String getInvalidPhoneMessage(BuildContext context) {
    return 'Invalid phone number';
  }
}
