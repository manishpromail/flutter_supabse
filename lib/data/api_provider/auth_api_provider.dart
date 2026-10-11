import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/network_handling.dart';
import '../../features/auth/data/user_model.dart';
import '../injector.dart';
import '../shared/data_response.dart';

/// AuthApiProvider handling remote authentication requests via Dio
class AuthApiProvider {
  late final Dio _dio;

  AuthApiProvider([Dio? dio]) {
    _dio = dio ?? Injector().getDio();
  }

  /// Register a new user
  Future<DataResponse<UserModel>> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final Response response = await _dio.post(
        ApiConstants.signup,
        data: {
          'email': email.trim(),
          'password': password.trim(),
          'name': name?.trim() ?? '',
        },
      );

      final Map<String, dynamic> body = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : {};

      final userData = body['user'] as Map<String, dynamic>? ?? {};
      final user = UserModel.fromJson(userData);

      return DataResponse.success(
        data: user,
        message: body['message']?.toString() ?? 'Signup successful',
        statusCode: response.statusCode ?? 201,
      );
    } catch (e) {
      return DataResponse.failure(
        message: NetworkHandling.getDioException(e),
        statusCode: NetworkHandling.getDioCode(e),
      );
    }
  }

  /// Sign in user
  Future<DataResponse<Map<String, dynamic>>> logIn({
    required String email,
    required String password,
  }) async {
    try {
      final Response response = await _dio.post(
        ApiConstants.login,
        data: {
          'email': email.trim(),
          'password': password.trim(),
        },
      );

      final Map<String, dynamic> body = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : {};

      return DataResponse.success(
        data: body,
        message: body['message']?.toString() ?? 'Login successful',
        statusCode: response.statusCode ?? 200,
      );
    } catch (e) {
      return DataResponse.failure(
        message: NetworkHandling.getDioException(e),
        statusCode: NetworkHandling.getDioCode(e),
      );
    }
  }

  /// Fetch currently authenticated user profile
  Future<DataResponse<UserModel>> getCurrentUser() async {
    try {
      final Response response = await _dio.get(
        ApiConstants.profile,
        options: Injector.getHeaderToken(),
      );

      final Map<String, dynamic> body = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : {};

      final UserModel user = UserModel.fromJson(
        (body['user'] ?? body) as Map<String, dynamic>,
      );

      return DataResponse.success(
        data: user,
        message: 'Profile fetched successfully',
        statusCode: response.statusCode ?? 200,
      );
    } catch (e) {
      return DataResponse.failure(
        message: NetworkHandling.getDioException(e),
        statusCode: NetworkHandling.getDioCode(e),
      );
    }
  }
}
