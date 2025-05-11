import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:parking_app/core/services/auth_signin_service.dart';
import 'package:parking_app/core/utils/auth_providers.dart';
import 'package:parking_app/views/auth/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:parking_app/views/auth/signin_screen.dart';
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
      child: Builder(
        builder: (context) {
          return MaterialApp(
            title: 'パーキングアプリ',
            theme:
                AppTheme.lightTheme(), // Apply the light theme with NotoSansJP
            darkTheme:
                AppTheme.darkTheme(), // Apply the dark theme with NotoSansJP
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
              AppLocalizations.of(context); // Ensures localization is loaded
              return AppLocalizations.of(context).appTitle;
            },

            // Initial route handler checks authentication status
            home: const InitialRouteHandler(),

            // Define routes for navigation
            routes: {
              '/login': (context) => const SignInScreen(),
              '/register':
                  (context) => const Center(
                    child: Text('Register Screen - Coming Soon'),
                  ),
              '/forgot-password':
                  (context) => const Center(
                    child: Text('Forgot Password - Coming Soon'),
                  ),
              '/user-home':
                  (context) =>
                      const Center(child: Text('User Home - redirecting...')),
              '/owner-home':
                  (context) =>
                      const Center(child: Text('Owner Home - redirecting...')),
            },
          );
        },
      ),
    );
  }
}

class InitialRouteHandler extends StatefulWidget {
  const InitialRouteHandler({super.key});

  @override
  State<InitialRouteHandler> createState() => _InitialRouteHandlerState();
}

class _InitialRouteHandlerState extends State<InitialRouteHandler> {
  @override
  void initState() {
    super.initState();

    // Check authentication status after widget is inserted into the tree
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndNavigate();
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    final authService = Provider.of<AuthSignInService>(context, listen: false);

    try {
      await authService.checkAndRefreshToken();

      if (authService.isAuthenticated && mounted) {
        // If user is authenticated, get user info and navigate to home
        final userInfoResponse = await authService.getUserInfo();

        if (userInfoResponse.isSuccess && userInfoResponse.data != null) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder:
                    (context) => HomePage(
                      authUserModel: userInfoResponse.data!,
                      isOwner: userInfoResponse.data!.is_owner,
                    ),
              ),
            );
          }
        } else {
          // Token might be invalid, go to login
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        }
      } else {
        // Not authenticated, go to login
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      // Error occurred, go to login
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while checking authentication
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/app_logo.png',
              height: 120,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.local_parking,
                  size: 80.0,
                  color: Colors.indigo,
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'パーキングアプリ',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
