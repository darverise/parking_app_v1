import 'package:dio/dio.dart';
import 'package:parking_app/core/api/api_constants.dart';
import 'package:parking_app/core/api/api_response.dart';
import 'package:parking_app/core/client/dio_client.dart';
import 'package:parking_app/core/models/auth_signin_model.dart';
import 'package:flutter/material.dart';

class AuthSignInApi {
  final DioClient _client;
  AuthSignInApi(this._client);

  Future<ApiResponse<AuthUserModel>> signin(SignInRequest request) async {
    try {
      // Ensure email field is present and not null
      if (request.email.isEmpty) {
        return ApiResponse.error("Email is required");
      }

      // First, try to fetch a CSRF token if we don't have one
      if (await _client.csrfTokenProvider.getCsrfToken() == null) {
        try {
          await _client.get('/api/csrf-token');
        } catch (_) {
          // Ignore errors, just trying to get a token
        }
      }

      // Log request (avoid logging sensitive data in production)
      debugPrint('Sending signin request: ${request.toJson()}');

      final response = await _client.post(
        ApiConstants.SIGNIN,
        data: request.toJson(),
      );

      // Log response (avoid in production)
      debugPrint('Signin response: ${response.data}');

      return ApiResponse.fromJson(
        response.data,
        (data) => AuthUserModel.fromJson(data),
      );
    } catch (e) {
      debugPrint('Signin error: $e');
      if (e is DioException && e.response != null) {
        return ApiResponse.error(
          'Error: ${e.response!.statusCode} - ${e.response!.statusMessage ?? e.message}',
          code: e.response!.statusCode,
        );
      }
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<void>> signout() async {
    try {
      final response = await _client.post(
        ApiConstants.SIGNOUT, // Updated to use just the path
      );
      return ApiResponse.fromJson(response.data, (_) {});
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<AuthUserModel>> refreshToken(String refreshToken) async {
    try {
      final response = await _client.post(
        ApiConstants.REFRESH_TOKEN, // Updated to use just the path
        data: {'refreshToken': refreshToken},
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => AuthUserModel.fromJson(data),
      );
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<AuthUserModel>> getUserInfo() async {
    try {
      final response = await _client.get(
        ApiConstants.USER_INFO, // Updated to use just the path
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => AuthUserModel.fromJson(data),
      );
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<AuthUserModel>> updateUser(
    UpdateUserRequest request,
  ) async {
    try {
      final response = await _client.post(
        ApiConstants.UPDATE_USER, // Updated to use just the path
        data: request.toJson(),
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => AuthUserModel.fromJson(data),
      );
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<void>> changePassword(
    ChangePasswordRequest request,
  ) async {
    try {
      final response = await _client.post(
        ApiConstants.CHANGE_PASSWORD, // Updated to use just the path
        data: request.toJson(),
      );
      return ApiResponse.fromJson(response.data, (_) {});
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Upload user avatar and return the avatar URL
  Future<ApiResponse<String>> uploadAvatar(FormData formData) async {
    try {
      final response = await _client.upload(
        ApiConstants.UPLOAD_AVATAR, // Updated to use just the path
        formData: formData,
      );

      // Check if we need to parse the response differently
      return ApiResponse.fromJson(response.data, (dynamic data) {
        // Handle different response formats
        if (data is String) {
          // Direct string response (avatar URL)
          return data;
        } else if (data is Map) {
          // JSON object with URL field
          return data['url'] ?? data['avatarUrl'] ?? data['path'] ?? '';
        } else {
          // Fallback for unexpected response format
          return '';
        }
      });
    } catch (e) {
      // Handle errors
      if (e is DioException) {
        return ApiResponse.error(
          e.message ?? 'Upload failed',
          code: e.response?.statusCode,
        );
      }
      return ApiResponse.error(e.toString());
    }
  }

  static String? validateEmailOrPhone(String? value, BuildContext context) {
    final l10n = Localizations.of(context, dynamic);
    if (value == null || value.isEmpty) {
      return l10n.requiredField;
    }
    if (value.contains('@')) {
      final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      if (!emailRegExp.hasMatch(value)) {
        return l10n?.invalidEmail ?? 'メールアドレスが正しくありません';
      }
    } else {
      final phoneRegExp = RegExp(r'^\d{10,15}$');
      if (!phoneRegExp.hasMatch(value.replaceAll(RegExp(r'[^0-9]'), ''))) {
        return l10n?.invalidInput ?? '入力が正しくありません';
      }
    }
    return null;
  }

  static String? validatePassword(String? value, BuildContext context) {
    final l10n = Localizations.of(context, dynamic);
    if (value == null || value.isEmpty) {
      return l10n.requiredField;
    }
    if (value.length < 6) {
      return l10n.passwordTooShort;
    }
    return null;
  }
}
