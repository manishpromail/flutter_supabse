
class ApiConstants {
  // Increased connect timeout to 45 seconds to allow for Render free tier cold starts
  static const Duration connectTimeout = Duration(seconds: 45);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Production backend deployed on Render
  static String get baseUrl => 'https://flutter-supabase-backend-bdv6.onrender.com';

  // Relative API endpoint paths used with Dio baseUrl
  static const String signup = '/api/auth/signup';
  static const String login = '/api/auth/login';
  static const String profile = '/api/auth/me';
  static const String products = '/api/products';
}
