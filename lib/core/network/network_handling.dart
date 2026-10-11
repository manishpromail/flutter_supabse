import 'dart:io';
import 'package:dio/dio.dart';

/// Network error handling utility converting Dio and network exceptions into user-friendly message strings.
class NetworkHandling {
  NetworkHandling._();

  static String getDioException(dynamic error) {
    if (error is DioException) {
      if (error.response?.data != null && error.response?.data is Map<String, dynamic>) {
        final Map<String, dynamic> data = error.response!.data as Map<String, dynamic>;
        final String? msg = (data['message'] ?? data['error'])?.toString();
        if (msg != null && msg.isNotEmpty) {
          return msg;
        }
      }

      switch (error.type) {
        case DioExceptionType.cancel:
          return 'Request was canceled';
        case DioExceptionType.connectionTimeout:
          return 'Connection timed out';
        case DioExceptionType.sendTimeout:
          return 'Send timed out';
        case DioExceptionType.receiveTimeout:
          return 'Receive timed out';
        case DioExceptionType.badCertificate:
          return 'Bad SSL certificate';
        case DioExceptionType.connectionError:
          return 'Please check your internet connection or backend server';
        case DioExceptionType.badResponse:
          final int? statusCode = error.response?.statusCode;
          switch (statusCode) {
            case 400:
              return 'Bad request. Please verify your inputs.';
            case 401:
              return 'Invalid credentials or unauthorized';
            case 403:
              return 'Access forbidden';
            case 404:
              return 'Requested resource not found';
            case 408:
              return 'Request timed out';
            case 500:
              return 'Internal server error. Please try again later.';
            case 502:
              return 'Bad gateway';
            case 503:
              return 'Service unavailable';
            default:
              return error.response?.statusMessage ?? 'Something went wrong ($statusCode)';
          }
        case DioExceptionType.unknown:
          if (error.error is SocketException) {
            return 'Cannot reach backend server. Make sure it is running on port 3000.';
          }
          return error.message ?? 'Unexpected network error occurred';
        default:
          return error.message ?? 'Network request failed';
      }
    } else if (error is SocketException) {
      return 'Cannot reach backend server. Make sure it is running on port 3000.';
    } else if (error is FormatException) {
      return 'Data format error occurred';
    }

    return error?.toString() ?? 'An unexpected error occurred';
  }

  static int getDioCode(dynamic error) {
    if (error is DioException) {
      return error.response?.statusCode ?? 0;
    }
    return 0;
  }
}
