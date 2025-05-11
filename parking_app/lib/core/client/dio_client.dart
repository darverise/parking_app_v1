import 'package:dio/dio.dart';
import 'package:parking_app/core/api/api_client.dart';
import 'package:parking_app/core/interceptors/app_interceptor.dart';

class DioClient implements ApiClient {
  static DioClient? _instance;
  final Dio _dio;

  factory DioClient({required AppInterceptors appInterceptors}) {
    _instance ??= DioClient._internal(appInterceptors);
    return _instance!;
  }

  DioClient._internal(AppInterceptors appInterceptors) : _dio = Dio() {
    _dio.interceptors.add(appInterceptors);
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
}
