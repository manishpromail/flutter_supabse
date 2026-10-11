import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  /// Automatically resolves the correct host depending on platform:
  /// - Android Emulator: 10.0.2.2
  /// - iOS Simulator / macOS / Web / Desktop: localhost
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:3000';
      }
    } catch (_) {}
    return 'http://localhost:3000';
  }

  // Relative API endpoint paths used with Dio baseUrl
  static const String signup = '/api/auth/signup';
  static const String login = '/api/auth/login';
  static const String profile = '/api/auth/me';
  static const String products = '/api/products';
}
