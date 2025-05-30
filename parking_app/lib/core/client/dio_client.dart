import 'package:dio/dio.dart';
import 'package:parking_app/core/api/api_constants.dart';
import 'package:parking_app/core/api/api_client.dart';
import 'package:parking_app/core/interceptors/app_interceptor.dart';
import 'package:parking_app/core/security/csrf_token_provider.dart';

class DioClient implements ApiClient {
  static DioClient? _instance;
  final Dio _dio;
  final CsrfTokenProvider _csrfTokenProvider;

  factory DioClient({required AppInterceptors appInterceptors}) {
    _instance ??= DioClient._internal(appInterceptors);
    return _instance!;
  }

  DioClient._internal(AppInterceptors appInterceptors)
    : _dio = Dio(),
      _csrfTokenProvider = CsrfTokenProvider() {
    _dio.options.baseUrl = ApiConstants.BASE_URL;
    _dio.options.validateStatus = (status) => status! < 500;

    // Add CSRF token interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Only add CSRF token for non-safe methods
          if (![
            'GET',
            'HEAD',
            'OPTIONS',
            'TRACE',
          ].contains(options.method.toUpperCase())) {
            final token = await _csrfTokenProvider.getCsrfToken();
            if (token != null) {
              options.headers['X-CSRF-Token'] = token;
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Check for CSRF token in cookies and store it
          if (response.headers['set-cookie'] != null) {
            for (var cookie in response.headers['set-cookie']!) {
              if (cookie.contains('csrf_token=')) {
                final csrfToken = _extractCsrfTokenFromCookie(cookie);
                if (csrfToken != null) {
                  _csrfTokenProvider.setCsrfToken(csrfToken);
                }
                break;
              }
            }
          }
          return handler.next(response);
        },
      ),
    );

    _dio.interceptors.add(appInterceptors);
  }

  String? _extractCsrfTokenFromCookie(String cookie) {
    final regex = RegExp(r'csrf_token=([^;]+)');
    final match = regex.firstMatch(cookie);
    return match?.group(1);
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Response<T>> put<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Response<T>> delete<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Response<T>> upload<T>(
    String path, {
    required FormData formData,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(path, data: formData, options: options);
    } catch (e) {
      rethrow;
    }
  }

  Dio get dio => _dio;

  // Get the CSRF token provider
  CsrfTokenProvider get csrfTokenProvider => _csrfTokenProvider;
}
