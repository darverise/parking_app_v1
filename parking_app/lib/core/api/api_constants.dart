class ApiConstants {
  // Base URL from environment
  static final String BASE_URL = 'http://localhost:8080';

  // Auth endpoints
  static const String AUTH_BASE = '/api/auth';
  static const String SIGNIN = '$AUTH_BASE/signin';
  static const String SIGNOUT = '$AUTH_BASE/signout';
  static const String REFRESH_TOKEN = '$AUTH_BASE/refresh-token';
  static const String USER_INFO = '$AUTH_BASE/user';
  static const String UPDATE_USER = '$AUTH_BASE/user/update';
  static const String CHANGE_PASSWORD = '$AUTH_BASE/user/change-password';
  static const String UPLOAD_AVATAR = '$AUTH_BASE/user/upload-avatar';
  static const String REGISTER = '$AUTH_BASE/register';
  static const String VERIFY_CODE = '$AUTH_BASE/verify-code';
  static const String RESEND_CODE = '$AUTH_BASE/resend-code';

  static const String PARKING_SEARCH = '/parking-search';
}
