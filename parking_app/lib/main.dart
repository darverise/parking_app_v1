import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'views/auth/sign_in_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parking App',
      theme: AppTheme.lightTheme(), // Apply the light theme with NotoSansJP
      darkTheme: AppTheme.darkTheme(), // Apply the dark theme with NotoSansJP
      // Set up localization
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja'), // Japanese
        Locale('en'), // English
        Locale('zh'), // Chinese
      ],

      // Use system locale as default, or fall back to English
      locale: WidgetsBinding.instance.platformDispatcher.locale,

      // Home page is our SignInScreen
      home: const SignInScreen(),

      // Define routes for navigation
      routes: {
        '/login': (context) => const SignInScreen(),
        // Add more routes as you implement other screens
        // '/register': (context) => const RegisterScreen(),
        // '/home': (context) => const HomeScreen(),
      },
    );
  }
}
