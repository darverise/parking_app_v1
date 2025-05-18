import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class CsrfTokenProvider {
  static const String _tokenKey = 'csrf_token';
  String? _csrfToken;
  final Completer<String?> _tokenCompleter = Completer<String?>();
  bool _isInitialized = false;

  CsrfTokenProvider() {
    _initializeToken();
  }

  Future<void> _initializeToken() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _csrfToken = prefs.getString(_tokenKey);
      if (!_tokenCompleter.isCompleted) {
        _tokenCompleter.complete(_csrfToken);
      }
      _isInitialized = true;
    } catch (e) {
      if (!_tokenCompleter.isCompleted) {
        _tokenCompleter.complete(null);
      }
    }
  }

  Future<String?> getCsrfToken() async {
    if (_isInitialized) {
      return _csrfToken;
    }
    return _tokenCompleter.future;
  }

  Future<void> setCsrfToken(String token) async {
    _csrfToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (e) {
      print('Failed to save CSRF token: $e');
    }
  }

  Future<void> clearCsrfToken() async {
    _csrfToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (e) {
      print('Failed to clear CSRF token: $e');
    }
  }
}
