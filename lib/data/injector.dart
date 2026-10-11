import 'dart:developer';
import 'package:dio/dio.dart';
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

  static Options? getHeaderToken() {
    final String? token = StorageHelper().getUserToken();
    if (token != null && token.isNotEmpty) {
      return Options(headers: {'Authorization': 'Bearer $token'});
    }
    return null;
  }
}
