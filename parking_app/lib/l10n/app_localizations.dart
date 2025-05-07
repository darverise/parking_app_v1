import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

export 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Extension to easily access AppLocalizations using BuildContext
extension LocalizationExt on BuildContext {
  /// Get AppLocalizations instance
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

/// Helper class for managing localizations in the app
class AppLocalizationSetup {
  /// Supported locales for the application
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('ja'), // Japanese
    Locale('zh'), // Chinese
  ];

  /// Delegates required for localization
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  /// Helper method to determine if locale is supported
  static bool isLocaleSupported(Locale locale) {
    for (final supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }

  /// Locale resolution callback to determine which locale to use
  static Locale? localeResolutionCallback(
    Locale? locale,
    Iterable<Locale> supportedLocales,
  ) {
    if (locale == null) {
      return supportedLocales.first;
    }

    // More efficient approach - directly return matching locale
    return supportedLocales.firstWhere(
      (supportedLocale) => supportedLocale.languageCode == locale.languageCode,
      orElse: () => supportedLocales.first,
    );
  }
}
