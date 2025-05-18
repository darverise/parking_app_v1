// lib/core/auth/auth_signin_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:parking_app/core/models/auth_signin_model.dart';
import 'package:parking_app/core/auth/auth_signin_api.dart';
import 'package:parking_app/core/api/api_response.dart';

class AuthSignInService extends ChangeNotifier {
  final AuthSignInApi _api;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthUserModel? _currentUser;
  bool _isLoading = false;

  AuthSignInService(this._api);

  // Getters
  AuthUserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  // Sign in with username/email and password
  Future<ApiResponse<AuthUserModel>> signIn(
    String username,
    String password,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.signin(
        SignInRequest(email: username, password: password),
      );

      if (response.isSuccess && response.data != null) {
        _currentUser = response.data;

        // Save auth data to secure storage
        await _storage.write(key: 'token', value: response.data!.token);
        await _storage.write(
          key: 'refresh_token',
          value: response.data!.refreshToken,
        );
        await _storage.write(key: 'user_id', value: response.data!.id);
        await _storage.write(key: 'user_email', value: response.data!.email);
        await _storage.write(
          key: 'is_owner',
          value: response.data!.is_owner.toString(),
        );
      }

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ApiResponse.error(e.toString());
    }
  }

  /// UI调用的统一登录方法，包含校验和业务逻辑
  Future<AuthUserModel?> signInWithValidation({
    required BuildContext context,
    required String username,
    required String password,
    required bool rememberMe,
    required bool isOwnerSelected,
    required Function(String?) onError,
  }) async {
    final response = await signIn(username, password);

    if (!response.isSuccess || response.data == null) {
      onError(response.message ?? "Login failed");
      return null;
    }

    final authUserModel = response.data!;
    final bool isOwner = authUserModel.is_owner;
    if ((isOwnerSelected && !isOwner) || (!isOwnerSelected && isOwner)) {
      onError(
        // 尽量用本地化
        Localizations.of(context, dynamic)?.invalidInput ?? "権限が一致しません",
      );
      return null;
    }

    await rememberUserLogin(rememberMe);
    return authUserModel;
  }

  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _api.signout();
    } catch (e) {
      // Even if API call fails, clear local data
      debugPrint('Error during signout: $e');
    } finally {
      _currentUser = null;

      // Clear all stored data
      await _storage.deleteAll();

      _isLoading = false;
      notifyListeners();
    }
  }

  // Check if token is valid and refresh if needed
  Future<bool> checkAndRefreshToken() async {
    final token = await _storage.read(key: 'token');
    final refreshToken = await _storage.read(key: 'refresh_token');

    if (token == null || refreshToken == null) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Get user info with current token
      final userInfoResponse = await getUserInfo();

      if (userInfoResponse.isSuccess && userInfoResponse.data != null) {
        _currentUser = userInfoResponse.data;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Token might be invalid, try to refresh it or sign out
      await signOut();
      return false;
    } catch (e) {
      debugPrint('Error checking token: $e');
      await signOut();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get user info
  Future<ApiResponse<AuthUserModel>> getUserInfo() async {
    try {
      final response = await _api.getUserInfo();

      if (response.isSuccess && response.data != null) {
        _currentUser = response.data;
        notifyListeners();
      }

      return response;
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Update user profile
  Future<ApiResponse<AuthUserModel>> updateUser(
    UpdateUserRequest request,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.updateUser(request);

      if (response.isSuccess && response.data != null) {
        _currentUser = response.data;
      }

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ApiResponse.error(e.toString());
    }
  }

  // Change password
  Future<ApiResponse<void>> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final request = ChangePasswordRequest(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      final response = await _api.changePassword(request);

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ApiResponse.error(e.toString());
    }
  }

  // Remember user login preference
  Future<void> rememberUserLogin(bool remember) async {
    await _storage.write(key: 'remember_user', value: remember.toString());

    if (remember && _currentUser != null) {
      // Save email for next login if remember is enabled
      await _storage.write(key: 'saved_email', value: _currentUser!.email);
    } else {
      // Clear saved email if remember is disabled
      await _storage.delete(key: 'saved_email');
    }
  }

  // Check if user selected "remember me"
  Future<bool> isRememberUserLogin() async {
    final value = await _storage.read(key: 'remember_user');
    return value == 'true';
  }

  // Get saved email if "remember me" was selected
  Future<String?> getSavedEmail() async {
    final isRemember = await isRememberUserLogin();
    if (isRemember) {
      return await _storage.read(key: 'saved_email');
    }
    return null;
  }
}
