class ResponseModel<T> {
  final bool success;
  final int statusCode;
  final String message;
  final T? data;
  final Map<String, dynamic>? headers;
  final String? error;

  ResponseModel({
    required this.success,
    required this.statusCode,
    this.message = '',
    this.data,
    this.headers,
    this.error,
  });

  factory ResponseModel.success({
    required int statusCode,
    String message = 'Success',
    T? data,
    Map<String, dynamic>? headers,
  }) {
    return ResponseModel(
      success: true,
      statusCode: statusCode,
      message: message,
      data: data,
      headers: headers,
    );
  }

  factory ResponseModel.error({
    required int statusCode,
    required String message,
    String? error,
    Map<String, dynamic>? headers,
  }) {
    return ResponseModel(
      success: false,
      statusCode: statusCode,
      message: message,
      error: error,
      headers: headers,
    );
  }

  factory ResponseModel.networkError({
    String message = 'Network Error',
    String? error,
  }) {
    return ResponseModel(
      success: false,
      statusCode: 0, // 0 indicates network error
      message: message,
      error: error,
    );
  }

  // Useful for debugging and logging
  @override
  String toString() {
    return 'ResponseModel{success: $success, statusCode: $statusCode, message: $message, data: $data, error: $error}';
  }
}
