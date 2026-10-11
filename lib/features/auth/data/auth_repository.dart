import '../../../data/api_provider/auth_api_provider.dart';
import '../../../utils/helper/storage_helper.dart';
import 'user_model.dart';

class AuthRepository {
  final AuthApiProvider _apiProvider;

  AuthRepository({AuthApiProvider? apiProvider})
      : _apiProvider = apiProvider ?? AuthApiProvider();

  Future<void> signup({
    required String email,
    required String password,
    String? name,
  }) async {
    final response = await _apiProvider.signUp(
      email: email,
      password: password,
      name: name,
    );

    if (!response.isSuccess) {
      throw Exception(response.message ?? 'Signup failed');
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiProvider.logIn(
      email: email,
      password: password,
    );

    if (!response.isSuccess) {
      throw Exception(response.message ?? 'Login failed');
    }

    final data = response.data;
    final token = data?['token'] as String?;
    final userData = data?['user'] as Map<String, dynamic>?;

    if (token == null || userData == null) {
      throw Exception('Invalid response format from server');
    }

    final user = UserModel.fromJson(userData);

    // Save session in StorageHelper
    await StorageHelper().saveUserToken(token);
    await StorageHelper().saveUserModel(user);
    await StorageHelper().saveIsLoggedIn(true);

    return user;
  }

  Future<UserModel?> getSavedUser() async {
    final isLoggedIn = StorageHelper().isLoggedIn();
    if (!isLoggedIn) return null;
    return StorageHelper().getUserModel();
  }

  Future<void> logout() async {
    await StorageHelper().clearAll();
  }
}
