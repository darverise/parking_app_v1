import 'package:dio/dio.dart';
import 'package:parking_app/core/api/api_constants.dart';
import 'package:parking_app/core/api/api_response.dart';
import 'package:parking_app/core/client/dio_client.dart';
import 'package:parking_app/core/models/auth_signin_model.dart';

class AuthSignInApi {
  final DioClient _client;
  AuthSignInApi(this._client);

  Future<ApiResponse<AuthUserModel>> signin(SignInRequest request) async {
    try {
      final response = await _client.post(
        ApiConstants.BASE_URL + ApiConstants.SIGNIN,
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

  Future<ApiResponse<void>> signout() async {
    try {
      final response = await _client.post(
        ApiConstants.BASE_URL + ApiConstants.SIGNOUT,
      );
      return ApiResponse.fromJson(response.data, (_) {});
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<AuthUserModel>> refreshToken(String refreshToken) async {
    try {
      final response = await _client.post(
        ApiConstants.BASE_URL + ApiConstants.REFRESH_TOKEN,
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
        ApiConstants.BASE_URL + ApiConstants.USER_INFO,
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
        ApiConstants.BASE_URL + ApiConstants.UPDATE_USER,
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
        ApiConstants.BASE_URL + ApiConstants.CHANGE_PASSWORD,
        data: request.toJson(),
      );
      return ApiResponse.fromJson(response.data, (_) {});
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Upload user avatar and return the avatar URL
  ///
  /// Fixed to handle different response structures
  Future<ApiResponse<String>> uploadAvatar(FormData formData) async {
    try {
      final response = await _client.upload(
        ApiConstants.BASE_URL + ApiConstants.UPLOAD_AVATAR,
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
}
