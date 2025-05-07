import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

// Authentication interceptor for adding auth tokens to requests
class AuthInterceptor extends Interceptor {
  final Function getToken;
  final Function refreshToken;

  AuthInterceptor({required this.getToken, required this.refreshToken});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth token for requests that don't require authentication
    if (options.extra['requiresAuth'] == false) {
      return handler.next(options);
    }

    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 errors (unauthorized) - attempt to refresh token
    if (err.response?.statusCode == 401) {
      try {
        final isRefreshed = await refreshToken();
        if (isRefreshed) {
          // Retry the original request with the new token
          final token = await getToken();
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $token';

          // Create a new request with the updated headers
          final response = await Dio().fetch(options);
          return handler.resolve(response);
        }
      } catch (e) {
        // If token refresh fails, continue with the error
      }
    }
    return handler.next(err);
  }
}

// Logger interceptor for debugging
class LoggerInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      print('┌─────────────────── REQUEST ───────────────────');
      print('│ URL: ${options.baseUrl}${options.path}');
      print('│ METHOD: ${options.method}');
      print('│ HEADERS: ${options.headers}');
      if (options.data != null) {
        print('│ BODY: ${jsonEncode(options.data)}');
      }
      print('└───────────────────────────────────────────────');
    }
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      print('┌─────────────────── RESPONSE ──────────────────');
      print('│ STATUS CODE: ${response.statusCode}');
      print('│ HEADERS: ${response.headers}');
      if (response.data != null) {
        print('│ BODY: ${jsonEncode(response.data)}');
      }
      print('└───────────────────────────────────────────────');
    }
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      print('┌─────────────────── ERROR ─────────────────────');
      print('│ STATUS CODE: ${err.response?.statusCode}');
      print('│ MESSAGE: ${err.message}');
      if (err.response?.data != null) {
        print('│ BODY: ${jsonEncode(err.response?.data)}');
      }
      print('└───────────────────────────────────────────────');
    }
    return handler.next(err);
  }
}

// Connectivity interceptor to handle network issues
class ConnectivityInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Here you would check for connectivity before making a request
    // For example, using connectivity_plus package
    // This is a simplified version
    try {
      return handler.next(options);
    } catch (e) {
      return handler.reject(
        DioException(
          requestOptions: options,
          error: 'No internet connection',
          type: DioExceptionType.connectionError,
        ),
      );
    }
  }
}

// Caching interceptor (basic implementation)
class CacheInterceptor extends Interceptor {
  final Map<String, Response> _cache = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Only cache GET requests
    if (options.method == 'GET') {
      String key = options.uri.toString();
      if (_cache.containsKey(key) && options.extra['forceRefresh'] != true) {
        return handler.resolve(_cache[key]!);
      }
    }
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Cache successful GET responses
    if (response.requestOptions.method == 'GET' && response.statusCode == 200) {
      String key = response.requestOptions.uri.toString();
      _cache[key] = response;
    }
    return handler.next(response);
  }
}
