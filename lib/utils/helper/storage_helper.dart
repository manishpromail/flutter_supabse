import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/data/user_model.dart';

/// StorageHelper singleton for session persistence
class StorageHelper {
  static late SharedPreferences _prefsInstance;

  static const String _userModel = "userModel";
  static const String _userId = "userId";
  static const String _isLoggedIn = "isLoggedIn";
  static const String _userToken = "userToken";

  static final StorageHelper _singleton = StorageHelper._internal();

  StorageHelper._internal();

  factory StorageHelper() {
    return _singleton;
  }

  static Future<void> init() async {
    _prefsInstance = await SharedPreferences.getInstance();
  }

  // User Token
  Future<bool> saveUserToken(String? token) async {
    if (token == null) {
      return await _prefsInstance.remove(_userToken);
    }
    return await _prefsInstance.setString(_userToken, token);
  }

  String? getUserToken() {
    return _prefsInstance.getString(_userToken);
  }

  // User Id
  Future<bool> saveUserId(String? id) async {
    if (id == null) {
      return await _prefsInstance.remove(_userId);
    }
    return await _prefsInstance.setString(_userId, id);
  }

  String? getUserId() {
    return _prefsInstance.getString(_userId);
  }

  // Logged In Status
  Future<bool> saveIsLoggedIn(bool value) async {
    return await _prefsInstance.setBool(_isLoggedIn, value);
  }

  bool isLoggedIn() {
    final token = getUserToken();
    return (token != null && token.isNotEmpty) ||
        (_prefsInstance.getBool(_isLoggedIn) ?? false);
  }

  // User Model
  Future<bool> saveUserModel(UserModel? user) async {
    if (user == null) {
      return await _prefsInstance.remove(_userModel);
    }
    final String jsonStr = jsonEncode(user.toJson());
    return await _prefsInstance.setString(_userModel, jsonStr);
  }

  UserModel? getUserModel() {
    final String? jsonStr = _prefsInstance.getString(_userModel);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final Map<String, dynamic> map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  // Clear / Logout
  Future<void> clearAll() async {
    await _prefsInstance.remove(_userToken);
    await _prefsInstance.remove(_userId);
    await _prefsInstance.remove(_userModel);
    await _prefsInstance.setBool(_isLoggedIn, false);
  }
}
