import 'package:flutter/material.dart';
import 'package:parking_app/core/routes/routes.dart';
import 'package:parking_app/views/auth/signin_screen.dart';

/// Class for handling route generation
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.LOGIN:
        return MaterialPageRoute(builder: (_) => const SignInScreen());
      // Other routes would be defined here
      default:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                body: Center(
                  child: Text('No route defined for ${settings.name}'),
                ),
              ),
        );
    }
  }
}
