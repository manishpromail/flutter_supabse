
enum BackendType {
  supabase,
  mongodb;

  String get displayName {
    switch (this) {
      case BackendType.supabase:
        return 'Supabase (PostgreSQL)';
      case BackendType.mongodb:
        return 'MongoDB (NoSQL)';
    }
  }

  String get shortName {
    switch (this) {
      case BackendType.supabase:
        return 'Supabase';
      case BackendType.mongodb:
        return 'MongoDB';
    }
  }

  String get defaultUrl {
    switch (this) {
      case BackendType.supabase:
        return 'https://flutter-supabase-backend-bdv6.onrender.com';
      case BackendType.mongodb:
        return 'https://flutter-mongodb.onrender.com';
    }
  }

  String get description {
    switch (this) {
      case BackendType.supabase:
        return 'Relational database powered by PostgreSQL & Supabase REST API.';
      case BackendType.mongodb:
        return 'Document NoSQL database powered by MongoDB Atlas & Mongoose.';
    }
  }
}

class ApiConstants {
  // Increased connect timeout to 45 seconds to allow for Render free tier cold starts
  static const Duration connectTimeout = Duration(seconds: 45);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Currently active backend service
  static BackendType activeBackend = BackendType.supabase;

  /// Optional custom override URL (e.g. for localhost or emulator)
  static String? _customUrl;

  /// Returns the effective base URL
  static String get baseUrl => _customUrl ?? activeBackend.defaultUrl;

  /// Sets the active backend and optional custom URL override
  static void setBackend(BackendType type, {String? customUrl}) {
    activeBackend = type;
    if (customUrl != null && customUrl.trim().isNotEmpty) {
      _customUrl = customUrl.trim();
    } else {
      _customUrl = null;
    }
  }

  /// Returns custom URL override if present
  static String? get customUrl => _customUrl;

  // Relative API endpoint paths used with Dio baseUrl
  static const String signup = '/api/auth/signup';
  static const String login = '/api/auth/login';
  static const String profile = '/api/auth/me';
  static const String products = '/api/products';
  static const String health = '/api/health';
}

