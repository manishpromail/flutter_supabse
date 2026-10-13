import 'dart:developer';
import 'package:dio/dio.dart';
import '../core/network/network_handling.dart';
import '../utils/helper/storage_helper.dart';
import '../core/constants/api_constants.dart';


/// Injector singleton configuring Dio instance with timeouts, logging interceptors, and auth headers.
class Injector {
  static final Injector _singleton = Injector._internal();
  static final Dio _dio = Dio();

  factory Injector() {
    return _singleton;
  }

  Injector._internal();

  Dio getDio() {
    final BaseOptions options = BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    _dio.options = options;
    _dio.interceptors.clear();

    // Attach custom Logging & Auth Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          final String? token = StorageHelper().getUserToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          log("--> ${options.method} ${options.uri}");
          if (options.data != null) {
            log("Data: ${options.data}");
          }
          handler.next(options);
        },
        onResponse: (Response response, ResponseInterceptorHandler handler) {
          log("<-- ${response.statusCode} ${response.requestOptions.uri}");
          handler.next(response);
        },
        onError: (DioException error, ErrorInterceptorHandler handler) {
          log("<-- ERROR ${error.response?.statusCode} ${error.requestOptions.uri}: ${error.message}");
          handler.next(error);
        },
      ),
    );

    return _dio;
  }

  /// Updates the baseUrl on the existing Dio instance immediately
  static void updateBaseUrl() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
  }

  /// Pings an endpoint healthcheck to verify reachability
  static Future<Map<String, dynamic>> testConnection(String targetBaseUrl) async {
    final testDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ),
    );

    try {
      final cleanUrl = targetBaseUrl.endsWith('/')
          ? targetBaseUrl.substring(0, targetBaseUrl.length - 1)
          : targetBaseUrl;
      final response = await testDio.get('$cleanUrl/api/health');
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Connected successfully',
          'data': response.data,
        };
      }
      return {
        'success': false,
        'message': 'Server returned code ${response.statusCode}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': NetworkHandling.getDioException(e),
      };
    }
  }

  static Options? getHeaderToken() {
    final String? token = StorageHelper().getUserToken();
    if (token != null && token.isNotEmpty) {
      return Options(headers: {'Authorization': 'Bearer $token'});
    }
    return null;
  }
}

