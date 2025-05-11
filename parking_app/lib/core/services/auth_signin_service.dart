import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:parking_app/core/auth/auth_signin_api.dart';
import 'package:parking_app/core/models/auth_signin_model.dart';

class AuthSignInService extends ChangeNotifier {
  final AuthSignInApi _api;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  AuthUserModel? _currentUser;

  AuthSignInService(this._api);

  AuthUserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<void> signIn(String username, String password) async {
    final response = await _api.signin(
      SignInRequest(username: username, password: password),
    );

    if (response.isSuccess && response.data != null) {
      _currentUser = response.data;
      await _storage.write(key: 'token', value: _currentUser!.token);
      await _storage.write(
        key: 'refreshToken',
        value: _currentUser!.refreshToken,
      );
      notifyListeners();
    } else {
      throw Exception(response.message);
    }
  }

  Future<void> signOut() async {
    await _api.signout();
    _currentUser = null;
    await _storage.deleteAll();
    notifyListeners();
  }

  Future<void> checkAndRefreshToken() async {
    final refreshToken = await _storage.read(key: 'refreshToken');
    if (refreshToken != null) {
      final response = await _api.refreshToken(refreshToken);
      if (response.isSuccess && response.data != null) {
        _currentUser = response.data;
        await _storage.write(key: 'token', value: _currentUser!.token);
        await _storage.write(
          key: 'refreshToken',
          value: _currentUser!.refreshToken,
        );
        notifyListeners();
        return;
      }
    }
    // If we get here, token refresh failed
    await signOut();
  }

  Future<void> rememberUserLogin(bool remember) async {
    await _storage.write(
      key: 'rememberUser',
      value: remember ? 'true' : 'false',
    );
  }

  Future<bool> isRememberUserLogin() async {
    final value = await _storage.read(key: 'rememberUser');
    return value == 'true';
  }
}
