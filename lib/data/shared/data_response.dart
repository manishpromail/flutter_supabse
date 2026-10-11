/// Generic API Response container encapsulating API payload, success status, and error messages uniformly.
class DataResponse<T> {
  final bool isSuccess;
  final String? message;
  final String? error;
  final T? data;
  final int? statusCode;

  const DataResponse({
    this.isSuccess = false,
    this.message,
    this.error,
    this.data,
    this.statusCode,
  });

  factory DataResponse.success({
    required T data,
    String? message,
    int statusCode = 200,
  }) {
    return DataResponse<T>(
      isSuccess: true,
      data: data,
      message: message,
      statusCode: statusCode,
    );
  }

  factory DataResponse.failure({
    required String message,
    String? error,
    int? statusCode,
  }) {
    return DataResponse<T>(
      isSuccess: false,
      message: message,
      error: error,
      statusCode: statusCode,
    );
  }

  factory DataResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    return DataResponse<T>(
      isSuccess: json['success'] as bool? ?? json['isSuccess'] as bool? ?? (json['error'] == null),
      message: json['message'] as String?,
      error: json['error'] as String?,
      statusCode: json['statusCode'] as int?,
      data: json['data'] != null ? fromJsonT(json['data']) : fromJsonT(json),
    );
  }
}
