import 'dart:io';
import 'package:dio/dio.dart';
import 'package:parking_app/core/api_endpoints.dart';
import 'package:parking_app/core/interceptors/interceptors.dart';
import 'package:parking_app/core/request_model.dart';
import 'package:parking_app/core/response_model.dart';

class DioClient {
  late final Dio _dio;

  // Singleton pattern
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );

    // Add interceptors
    _dio.interceptors.addAll([
      LoggerInterceptor(),
      ConnectivityInterceptor(),
      CacheInterceptor(),
      // AuthInterceptor will be added separately after initialization
    ]);
  }

  // Initialize auth interceptor with token getters
  void initializeAuthInterceptor({
    required Future<String?> Function() getToken,
    required Future<bool> Function() refreshToken,
  }) {
    _dio.interceptors.add(
      AuthInterceptor(getToken: getToken, refreshToken: refreshToken),
    );
  }

  // General request method
  Future<ResponseModel<T>> request<T>(RequestModel requestModel) async {
    try {
      final response = await _dio.request(
        requestModel.path,
        data: requestModel.data,
        queryParameters: requestModel.queryParameters,
        options: Options(
          method: requestModel.method,
          headers: requestModel.headers,
          responseType: requestModel.responseType,
          extra: {'requiresAuth': requestModel.requiresAuth},
        ),
      );

      return ResponseModel.success(
        statusCode: response.statusCode ?? 200,
        message: response.statusMessage ?? 'Success',
        data: response.data,
        headers: response.headers.map,
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    } on SocketException {
      return ResponseModel.networkError(
        message: 'Network connection error',
        error: 'Please check your internet connection',
      );
    } catch (e) {
      return ResponseModel.error(
        statusCode: 500,
        message: 'Unexpected error occurred',
        error: e.toString(),
      );
    }
  }

  // Handle Dio errors
  ResponseModel<T> _handleDioError<T>(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ResponseModel.networkError(
          message: 'Connection timed out',
          error: error.message,
        );
      case DioExceptionType.badResponse:
        return ResponseModel.error(
          statusCode: error.response?.statusCode ?? 400,
          message: error.response?.statusMessage ?? 'Bad response',
          error: _parseErrorMessage(error.response?.data),
        );
      case DioExceptionType.cancel:
        return ResponseModel.error(
          statusCode: 499, // Client closed request
          message: 'Request was cancelled',
          error: error.message,
        );
      case DioExceptionType.connectionError:
        return ResponseModel.networkError(
          message: 'Connection error',
          error: error.message,
        );
      case DioExceptionType.badCertificate:
        return ResponseModel.error(
          statusCode: 495, // SSL Certificate error
          message: 'Bad SSL certificate',
          error: error.message,
        );
      case DioExceptionType.unknown:
      default:
        return ResponseModel.error(
          statusCode: 500,
          message: 'Unknown error',
          error: error.message,
        );
    }
  }

  // Parse error message from response
  String? _parseErrorMessage(dynamic responseData) {
    if (responseData == null) return null;

    if (responseData is Map<String, dynamic>) {
      return responseData['message'] ??
          responseData['error'] ??
          responseData.toString();
    }

    if (responseData is String) {
      try {
        final Map<String, dynamic> jsonData = Map<String, dynamic>.from(
          responseData as Map<dynamic, dynamic>,
        );
        return jsonData['message'] ?? jsonData['error'] ?? responseData;
      } catch (_) {
        return responseData;
      }
    }

    return responseData.toString();
  }

  // Convenience methods for different HTTP methods
  Future<ResponseModel<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool requiresAuth = true,
  }) async {
    return request(
      RequestModel.get(
        path,
        queryParameters: queryParameters,
        headers: headers,
        requiresAuth: requiresAuth,
      ),
    );
  }

  Future<ResponseModel<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool requiresAuth = true,
  }) async {
    return request(
      RequestModel.post(
        path,
        data: data,
        queryParameters: queryParameters,
        headers: headers,
        requiresAuth: requiresAuth,
      ),
    );
  }

  Future<ResponseModel<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool requiresAuth = true,
  }) async {
    return request(
      RequestModel.put(
        path,
        data: data,
        queryParameters: queryParameters,
        headers: headers,
        requiresAuth: requiresAuth,
      ),
    );
  }

  Future<ResponseModel<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool requiresAuth = true,
  }) async {
    return request(
      RequestModel.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        headers: headers,
        requiresAuth: requiresAuth,
      ),
    );
  }
}
