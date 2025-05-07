import 'package:dio/dio.dart';

class RequestModel {
  final String path;
  final String method;
  final Map<String, dynamic>? queryParameters;
  final dynamic data;
  final Map<String, dynamic>? headers;
  final ResponseType? responseType;
  final bool requiresAuth;

  RequestModel({
    required this.path,
    required this.method,
    this.queryParameters,
    this.data,
    this.headers,
    this.responseType,
    this.requiresAuth = true,
  });

  // Factory methods for common HTTP methods
  factory RequestModel.get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    ResponseType? responseType,
    bool requiresAuth = true,
  }) {
    return RequestModel(
      path: path,
      method: 'GET',
      queryParameters: queryParameters,
      headers: headers,
      responseType: responseType,
      requiresAuth: requiresAuth,
    );
  }

  factory RequestModel.post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    ResponseType? responseType,
    bool requiresAuth = true,
  }) {
    return RequestModel(
      path: path,
      method: 'POST',
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      responseType: responseType,
      requiresAuth: requiresAuth,
    );
  }

  factory RequestModel.put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    ResponseType? responseType,
    bool requiresAuth = true,
  }) {
    return RequestModel(
      path: path,
      method: 'PUT',
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      responseType: responseType,
      requiresAuth: requiresAuth,
    );
  }

  factory RequestModel.delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    ResponseType? responseType,
    bool requiresAuth = true,
  }) {
    return RequestModel(
      path: path,
      method: 'DELETE',
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      responseType: responseType,
      requiresAuth: requiresAuth,
    );
  }
}
