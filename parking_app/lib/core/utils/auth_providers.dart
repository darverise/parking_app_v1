import 'package:flutter/material.dart';
import 'package:parking_app/core/services/auth_signin_service.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:parking_app/core/auth/auth_signin_api.dart';
import 'package:parking_app/core/client/dio_client.dart';
import 'package:parking_app/core/interceptors/app_interceptor.dart';

/// Helper class to set up authentication providers in the app
class AuthProviders {
  /// Creates all providers required for authentication
  static List<SingleChildWidget> providers() {
    return [
      // Provider for AppInterceptors
      Provider<AppInterceptors>(
        create:
            (context) => AppInterceptors(
              getToken: () async {
                // Implement token retrieval from secure storage
                const storage = FlutterSecureStorage();
                return await storage.read(key: 'token');
              },
              refreshToken: () async {
                // This will be called when a token needs refreshing
                try {
                  // Get the auth service to refresh the token
                  final authService = Provider.of<AuthSignInService>(
                    context,
                    listen: false,
                  );
                  await authService.checkAndRefreshToken();
                  return true;
                } catch (e) {
                  debugPrint('Token refresh failed: $e');
                  return false;
                }
              },
            ),
      ),

      // Provider for DioClient
      Provider<DioClient>(
        create:
            (context) =>
                DioClient(appInterceptors: context.read<AppInterceptors>()),
      ),

      // Provider for AuthSignInApi
      Provider<AuthSignInApi>(
        create: (context) => AuthSignInApi(context.read<DioClient>()),
      ),

      // Provider for AuthSignInService
      ChangeNotifierProvider<AuthSignInService>(
        create: (context) => AuthSignInService(context.read<AuthSignInApi>()),
      ),
    ];
  }
}
