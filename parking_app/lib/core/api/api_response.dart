enum ApiStatus { success, error, timeout, cancelled }

class ApiResponse<T> {
  final ApiStatus status;
  final T? data;
  final String? message;
  final int? code;

  ApiResponse.success(this.data)
    : status = ApiStatus.success,
      message = null,
      code = 200;

  ApiResponse.error(this.message, {this.code})
    : status = ApiStatus.error,
      data = null;

  ApiResponse.timeout({this.message})
    : status = ApiStatus.timeout,
      data = null,
      code = 408;

  ApiResponse.cancelled({this.message})
    : status = ApiStatus.cancelled,
      data = null,
      code = 499;

  bool get isSuccess => status == ApiStatus.success;

  static ApiResponse<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(dynamic) fromData,
  ) {
    if (json['code'] == 200) {
      return ApiResponse.success(fromData(json['data']));
    } else {
      return ApiResponse.error(
        json['message'] ?? 'Unknown error',
        code: json['code'],
      );
    }
  }
}
