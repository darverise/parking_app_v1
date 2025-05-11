import 'package:flutter/material.dart';

/// 定义应用中使用的所有路由
class AppRoutes {
  // 身份验证相关路由
  static const String LOGIN = '/login';
  static const String REGISTER = '/register';
  static const String FORGOT_PASSWORD = '/forgot-password';
  static const String VERIFY_EMAIL = '/verify-email';
  static const String RESET_PASSWORD = '/reset-password';
  static const String LOGOUT = '/logout';

  // 主要页面路由
  static const String HOME = '/home';
  static const String PROFILE = '/profile';
  static const String SETTINGS = '/settings';

  // 停车相关路由
  static const String FIND_PARKING = '/find-parking';
  static const String PARKING_DETAILS = '/parking-details';
  static const String BOOK_PARKING = '/book-parking';
  static const String RESERVATIONS = '/reservations';
  static const String PAYMENT_HISTORY = '/payment-history';

  // 车主专用路由
  static const String OWNER_DASHBOARD = '/owner-dashboard';
  static const String ADD_PARKING_SPACE = '/add-parking-space';
  static const String EDIT_PARKING_SPACE = '/edit-parking-space';
  static const String OWNER_RESERVATIONS = '/owner-reservations';
  static const String OWNER_ANALYTICS = '/owner-analytics';

  // 定义路由映射表，用于Navigator
  static Map<String, WidgetBuilder> getRoutes() {
    // 在实际项目中实现此方法
    return {};
  }
}
