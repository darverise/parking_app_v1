// lib/core/interceptors/interceptors.dart
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart'
    show Connectivity, ConnectivityResult;

/// 统一拦截器管理类，组合多个拦截器功能
class AppInterceptors extends Interceptor {
  // 依赖注入的token获取和刷新方法
  final Future<String?> Function() getToken;
  final Future<bool> Function() refreshToken;

  // 配置参数
  final bool enableLogging;
  final bool enableCache;
  final bool enableRetry;
  final int maxRetryCount;

  // 缓存存储
  final Map<String, CacheEntry> _cache = {};
  // 标记请求是否正在刷新token
  bool _isRefreshingToken = false;
  // 等待token刷新的请求队列
  final List<_RetryRequest> _tokenRefreshQueue = [];

  /// 创建应用拦截器
  AppInterceptors({
    required this.getToken,
    required this.refreshToken,
    this.enableLogging = kDebugMode,
    this.enableCache = true,
    this.enableRetry = true,
    this.maxRetryCount = 3,
  });

  /// 请求拦截
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // 1. 检查网络连接
      final connectivityResult = await _checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return _handleNoConnectivity(options, handler);
      }

      // 2. 处理缓存（只对GET请求）
      if (enableCache && options.method == 'GET') {
        final cacheResult = _handleCache(options);
        if (cacheResult != null) {
          return handler.resolve(cacheResult);
        }
      }

      // 3. 添加认证token（除非显式禁用）
      if (options.extra['requiresAuth'] != false) {
        await _addAuthorizationHeader(options);
      }

      // 4. 添加通用头部信息
      _addCommonHeaders(options);

      // 5. 记录请求日志
      if (enableLogging) {
        _logRequest(options);
      }

      // 继续请求
      return handler.next(options);
    } catch (e) {
      // 处理拦截器内部错误
      return handler.reject(
        DioException(
          requestOptions: options,
          error: 'Interceptor error: $e',
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  /// 响应拦截
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    try {
      // 1. 更新缓存
      if (enableCache &&
          response.requestOptions.method == 'GET' &&
          response.statusCode == 200) {
        _updateCache(response);
      }

      // 2. 记录响应日志
      if (enableLogging) {
        _logResponse(response);
      }

      // 3. 处理特定业务逻辑 (例如统一的API响应格式)
      final processedResponse = _processResponse(response);

      // 继续响应
      return handler.next(processedResponse);
    } catch (e) {
      // 处理拦截器内部错误
      return handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          error: 'Response interceptor error: $e',
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  /// 错误拦截
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    try {
      // 1. 记录错误日志
      if (enableLogging) {
        _logError(err);
      }

      // 2. 处理401错误（未授权 - 尝试刷新Token）
      if (err.response?.statusCode == 401 &&
          err.requestOptions.extra['isRetryAfterRefresh'] != true) {
        final retryResult = await _handleTokenRefresh(err, handler);
        if (retryResult) {
          // 已经处理完成，不继续向下传递错误
          return;
        }
      }

      // 3. 处理网络连接错误 - 尝试使用缓存
      if (enableCache &&
          _isNetworkError(err) &&
          err.requestOptions.method == 'GET') {
        final cachedResponse = _getCachedResponse(err.requestOptions);
        if (cachedResponse != null) {
          return handler.resolve(cachedResponse);
        }
      }

      // 4. 处理重试逻辑
      if (enableRetry && _shouldRetry(err)) {
        final retried = await _retryRequest(err, handler);
        if (retried) {
          // 已经处理重试，不继续向下传递错误
          return;
        }
      }

      // 5. 丰富错误信息
      final enhancedError = _enhanceError(err);

      // 继续传递错误
      return handler.next(enhancedError);
    } catch (e) {
      // 处理拦截器内部错误
      return handler.next(
        DioException(
          requestOptions: err.requestOptions,
          error: 'Error interceptor error: $e',
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  /// 检查网络连接
  Future<ConnectivityResult> _checkConnectivity() async {
    return await Connectivity().checkConnectivity();
  }

  /// 处理无网络连接情况
  void _handleNoConnectivity(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    // 检查是否有缓存可用
    if (enableCache && options.method == 'GET') {
      final cachedResponse = _getCachedResponse(options);
      if (cachedResponse != null) {
        return handler.resolve(cachedResponse);
      }
    }

    // 没有缓存，返回网络错误
    return handler.reject(
      DioException(
        requestOptions: options,
        error: 'No internet connection',
        type: DioExceptionType.connectionError,
      ),
    );
  }

  /// 添加认证头部
  Future<void> _addAuthorizationHeader(RequestOptions options) async {
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
  }

  /// 添加通用头部信息
  void _addCommonHeaders(RequestOptions options) {
    options.headers.putIfAbsent('Accept', () => 'application/json');
    options.headers.putIfAbsent('Content-Type', () => 'application/json');

    // 添加应用信息
    options.headers.putIfAbsent('X-App-Version', () => '1.0.0'); // 可以从应用配置中获取
    options.headers.putIfAbsent(
      'X-Platform',
      () => Platform.isIOS ? 'iOS' : 'Android',
    );

    // 添加设备信息
    // 这里可以添加更多设备信息，如设备ID、语言等
  }

  /// 处理缓存
  Response? _handleCache(RequestOptions options) {
    // 如果请求明确要求强制刷新，则跳过缓存
    if (options.extra['forceRefresh'] == true) {
      return null;
    }

    final cacheKey = _getCacheKey(options);
    final cacheEntry = _cache[cacheKey];

    // 检查缓存是否存在且未过期
    if (cacheEntry != null && !cacheEntry.isExpired()) {
      return cacheEntry.response;
    }

    return null;
  }

  /// 更新缓存
  void _updateCache(Response response) {
    final cacheKey = _getCacheKey(response.requestOptions);
    final cacheDuration =
        response.requestOptions.extra['cacheDuration'] as Duration? ??
        const Duration(minutes: 5); // 默认缓存5分钟

    _cache[cacheKey] = CacheEntry(
      response: response,
      timestamp: DateTime.now(),
      duration: cacheDuration,
    );
  }

  /// 获取缓存的响应
  Response? _getCachedResponse(RequestOptions options) {
    final cacheKey = _getCacheKey(options);
    final cacheEntry = _cache[cacheKey];

    if (cacheEntry != null) {
      // 标记这是来自缓存的响应
      final cachedResponse = Response(
        data: cacheEntry.response.data,
        headers: cacheEntry.response.headers,
        requestOptions: options,
        statusCode: cacheEntry.response.statusCode,
        isRedirect: cacheEntry.response.isRedirect,
        statusMessage: cacheEntry.response.statusMessage,
        redirects: cacheEntry.response.redirects,
        extra: {...cacheEntry.response.extra, 'fromCache': true},
      );

      return cachedResponse;
    }

    return null;
  }

  /// 获取缓存键
  String _getCacheKey(RequestOptions options) {
    return '${options.method}:${options.uri}:${jsonEncode(options.queryParameters)}';
  }

  /// 处理Token刷新
  Future<bool> _handleTokenRefresh(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 创建重试请求对象
    final retryRequest = _RetryRequest(
      options: err.requestOptions,
      handler: handler,
    );

    // 将请求添加到队列
    _tokenRefreshQueue.add(retryRequest);

    // 如果已经在刷新Token，则不重复刷新
    if (_isRefreshingToken) {
      return true;
    }

    _isRefreshingToken = true;

    try {
      final bool refreshed = await refreshToken();

      if (refreshed) {
        // 刷新成功，重试所有队列中的请求
        final newToken = await getToken();

        // 处理所有等待的请求
        while (_tokenRefreshQueue.isNotEmpty) {
          final request = _tokenRefreshQueue.removeAt(0);

          // 更新Authorization头
          if (newToken != null && newToken.isNotEmpty) {
            request.options.headers['Authorization'] = 'Bearer $newToken';
          }

          // 标记此请求是刷新Token后的重试，避免无限循环
          request.options.extra['isRetryAfterRefresh'] = true;

          try {
            // 使用新的Dio实例重试请求，避免拦截器循环
            final response = await Dio().fetch(request.options);
            request.handler.resolve(response);
          } catch (e) {
            if (e is DioException) {
              request.handler.reject(e);
            } else {
              request.handler.reject(
                DioException(
                  requestOptions: request.options,
                  error: e.toString(),
                ),
              );
            }
          }
        }

        return true;
      } else {
        // 刷新失败，拒绝所有请求
        _rejectAllTokenRefreshQueue('Token refresh failed');
        return false;
      }
    } catch (e) {
      // 刷新过程中出现错误
      _rejectAllTokenRefreshQueue('Token refresh error: $e');
      return false;
    } finally {
      _isRefreshingToken = false;
    }
  }

  /// 拒绝所有等待Token刷新的请求
  void _rejectAllTokenRefreshQueue(String errorMessage) {
    while (_tokenRefreshQueue.isNotEmpty) {
      final request = _tokenRefreshQueue.removeAt(0);
      request.handler.reject(
        DioException(
          requestOptions: request.options,
          error: errorMessage,
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  /// 判断是否应该重试请求
  bool _shouldRetry(DioException err) {
    // 获取当前重试次数
    final int retryCount = err.requestOptions.extra['retryCount'] ?? 0;

    // 如果已经达到最大重试次数，则不再重试
    if (retryCount >= maxRetryCount) {
      return false;
    }

    // 根据错误类型判断是否应该重试
    return _isNetworkError(err) ||
        _isServerError(err) ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout;
  }

  /// 重试请求
  Future<bool> _retryRequest(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;

    // 增加重试计数
    final int retryCount = options.extra['retryCount'] ?? 0;
    options.extra['retryCount'] = retryCount + 1;

    // 计算退避时间 (指数退避策略)
    final delay = Duration(milliseconds: 300 * (1 << retryCount));

    try {
      // 等待一段时间后重试
      await Future.delayed(delay);

      // 使用新的Dio实例重试请求，避免拦截器循环
      final response = await Dio().fetch(options);
      handler.resolve(response);
      return true;
    } catch (e) {
      // 重试失败
      return false;
    }
  }

  /// 判断是否为网络错误
  bool _isNetworkError(DioException err) {
    return err.type == DioExceptionType.connectionError ||
        err.error is SocketException;
  }

  /// 判断是否为服务器错误
  bool _isServerError(DioException err) {
    final statusCode = err.response?.statusCode;
    return statusCode != null && statusCode >= 500 && statusCode < 600;
  }

  /// 处理和丰富错误信息
  DioException _enhanceError(DioException err) {
    // 根据错误类型丰富错误信息
    String errorMessage;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage = '请求超时，请检查网络连接';
        break;
      case DioExceptionType.badResponse:
        errorMessage = _getHttpStatusErrorMessage(err.response?.statusCode);
        break;
      case DioExceptionType.cancel:
        errorMessage = '请求已取消';
        break;
      case DioExceptionType.connectionError:
        errorMessage = '网络连接错误，请检查网络设置';
        break;
      case DioExceptionType.badCertificate:
        errorMessage = '服务器证书验证失败';
        break;
      case DioExceptionType.unknown:
        errorMessage = err.message ?? '未知错误';

        // 如果是Socket异常，添加更友好的消息
        if (err.error is SocketException) {
          errorMessage = '无法连接到服务器，请检查网络连接';
        }
        break;
    }

    // 尝试从响应中获取更具体的错误信息
    if (err.response?.data is Map && err.response?.data['message'] != null) {
      errorMessage = err.response?.data['message'].toString() ?? errorMessage;
    }

    // 创建新的错误对象
    return DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: errorMessage,
    );
  }

  /// 根据HTTP状态码获取错误信息
  String _getHttpStatusErrorMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return '请求参数错误';
      case 401:
        return '未授权，请重新登录';
      case 403:
        return '访问被拒绝';
      case 404:
        return '请求的资源不存在';
      case 405:
        return '请求方法不允许';
      case 408:
        return '请求超时';
      case 409:
        return '资源冲突';
      case 500:
        return '服务器内部错误';
      case 501:
        return '服务未实现';
      case 502:
        return '网关错误';
      case 503:
        return '服务不可用';
      case 504:
        return '网关超时';
      default:
        return '请求失败 (${statusCode ?? "未知状态码"})';
    }
  }

  /// 处理API响应数据格式
  Response _processResponse(Response response) {
    // 如果API有统一的响应格式，可以在这里进行处理
    // 例如，如果所有API响应都包装在 {"code": 0, "data": {}, "message": ""} 中
    // 可以统一提取data字段

    if (response.data is Map &&
        response.data['code'] != null &&
        response.data['data'] != null) {
      final code = response.data['code'];

      // 检查业务代码是否表示成功
      if (code == 0 || code == 200) {
        // 提取data字段作为新的响应数据
        response.data = response.data['data'];
      } else {
        // 业务逻辑错误，可以转换为Dio错误
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: response.data['message'] ?? '业务处理失败',
        );
      }
    }

    return response;
  }

  /// 记录请求日志
  void _logRequest(RequestOptions options) {
    debugPrint('┌─────────────────── REQUEST ───────────────────');
    debugPrint('│ URL: ${options.uri}');
    debugPrint('│ METHOD: ${options.method}');
    debugPrint('│ HEADERS: ${_sanitizeHeaders(options.headers)}');

    if (options.data != null) {
      try {
        final data =
            options.data is String ? options.data : jsonEncode(options.data);
        debugPrint('│ BODY: $data');
      } catch (e) {
        debugPrint('│ BODY: [无法序列化]');
      }
    }

    debugPrint('└───────────────────────────────────────────────');
  }

  /// 记录响应日志
  void _logResponse(Response response) {
    debugPrint('┌─────────────────── RESPONSE ──────────────────');
    debugPrint('│ URL: ${response.requestOptions.uri}');
    debugPrint('│ STATUS: ${response.statusCode} ${response.statusMessage}');
    debugPrint('│ HEADERS: ${_sanitizeHeaders(response.headers.map)}');

    if (response.data != null) {
      try {
        final data =
            response.data is String ? response.data : jsonEncode(response.data);
        debugPrint('│ BODY: $data');
      } catch (e) {
        debugPrint('│ BODY: [无法序列化]');
      }
    }

    debugPrint('└───────────────────────────────────────────────');
  }

  /// 记录错误日志
  void _logError(DioException err) {
    debugPrint('┌─────────────────── ERROR ─────────────────────');
    debugPrint('│ URL: ${err.requestOptions.uri}');
    debugPrint('│ TYPE: ${err.type}');
    debugPrint(
      '│ STATUS: ${err.response?.statusCode} ${err.response?.statusMessage}',
    );
    debugPrint('│ MESSAGE: ${err.message}');

    if (err.response?.data != null) {
      try {
        final data =
            err.response?.data is String
                ? err.response?.data
                : jsonEncode(err.response?.data);
        debugPrint('│ RESPONSE: $data');
      } catch (e) {
        debugPrint('│ RESPONSE: [无法序列化]');
      }
    }

    debugPrint('└───────────────────────────────────────────────');
  }

  /// 净化头信息，移除敏感数据
  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = Map<String, dynamic>.from(headers);

    // 屏蔽敏感信息如授权令牌
    if (sanitized.containsKey('Authorization')) {
      sanitized['Authorization'] = 'Bearer [REDACTED]';
    }

    return sanitized;
  }
}

/// 缓存条目
class CacheEntry {
  final Response response;
  final DateTime timestamp;
  final Duration duration;

  CacheEntry({
    required this.response,
    required this.timestamp,
    required this.duration,
  });

  /// 判断缓存是否已过期
  bool isExpired() {
    return DateTime.now().difference(timestamp) > duration;
  }
}

/// 等待Token刷新的请求
class _RetryRequest {
  final RequestOptions options;
  final ErrorInterceptorHandler handler;

  _RetryRequest({required this.options, required this.handler});
}
