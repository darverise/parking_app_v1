class ApiEndpoints {
  // Base URL
  // Replace with your actual API base URL
  static const String baseUrl = 'https://api.parkingapp.com';

  // Auth Endpoints
  static const String login = '/auth/signin';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';

  // User Endpoints
  static const String userProfile = '/users/profile';
  static const String updateProfile = '/users/update';

  // Parking Endpoints
  static const String parkingSpots = '/parking/spots';
  static const String parkingReservation = '/parking/reservation';
  static const String parkingHistory = '/parking/history';

  // Payment Endpoints
  static const String paymentMethods = '/payment/methods';
  static const String makePayment = '/payment/process';
  static const String paymentHistory = '/payment/history';
}
