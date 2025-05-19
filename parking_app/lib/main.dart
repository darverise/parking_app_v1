import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:parking_app/core/services/auth_signin_service.dart';
import 'package:parking_app/core/utils/auth_providers.dart';
import 'package:parking_app/views/auth/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:parking_app/views/auth/signin_screen.dart';
import 'package:parking_app/views/dummy_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Add all authentication providers
        ...AuthProviders.providers(),
      ],
      child: MaterialApp(
        title: 'パーキングアプリ',
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
          Locale('ja'), // Japanese (default)
          Locale('en'), // English
          Locale('zh'), // Chinese
        ],

        // Set Japanese as default locale
        locale: const Locale('ja'),

        // Initialize the localization helper
        onGenerateTitle: (context) {
          // Set the active context for the localization helper
          return AppLocalizations.of(context).appTitle ?? 'パーキングアプリ';
        },

        // Initial route handler checks authentication status
        initialRoute: '/dummy',

        // Define routes for navigation
        routes: {
          '/': (context) => const SplashScreen(),
          '/dummy': (context) => const DummyScreen(),
          '/login': (context) => const SignInScreen(),
          '/register':
              (context) =>
                  const Center(child: Text('Register Screen - Coming Soon')),
          '/forgot-password':
              (context) =>
                  const Center(child: Text('Forgot Password - Coming Soon')),
          '/user-home':
              (context) =>
                  const Center(child: Text('User Home - redirecting...')),
          '/owner-home':
              (context) =>
                  const Center(child: Text('Owner Home - redirecting...')),
        },
      ),
    );
  }
}

// Create a proper splash screen as entry point
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers properly
    _fadeController = AnimationController(
      vsync: this, // Using this as TickerProvider is correct
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    // Start the animation
    _fadeController.forward();

    // Check authentication after splash screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () {
        _checkAuthAndNavigate();
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndNavigate() async {
    // 直接跳转到 DummyScreen
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.of(context).pushReplacementNamed('/dummy');
    }
  }

  // Add state variables for loading feedback
  String _loadingText = "ログイン情報を確認中...";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo with fade-in and scale animation
            AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      height: 150,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.local_parking,
                          size: 100.0,
                          color: Colors.indigo,
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            // App name with fade-in animation
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                'パーキングアプリ',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Loading text feedback
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                _loadingText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Loading indicator
            FadeTransition(
              opacity: _fadeAnimation,
              child: const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
