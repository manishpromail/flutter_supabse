import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../../features/auth/data/user_model.dart';

/// StorageHelper singleton for session and configuration persistence
class StorageHelper {
  static late SharedPreferences _prefsInstance;

  static const String _legacyUserModel = "userModel";
  static const String _legacyUserId = "userId";
  static const String _legacyIsLoggedIn = "isLoggedIn";
  static const String _legacyUserToken = "userToken";

  static const String _selectedBackendKey = "selected_backend_type";
  static const String _customBackendUrlKeyPrefix = "custom_backend_url_";

  static final StorageHelper _singleton = StorageHelper._internal();

  StorageHelper._internal();

  factory StorageHelper() {
    return _singleton;
  }

  static Future<void> init() async {
    _prefsInstance = await SharedPreferences.getInstance();
  }

  // --- Backend Configuration Persistence ---

  /// Returns whether the user has explicitly selected a backend before
  bool hasSelectedBackend() {
    return _prefsInstance.containsKey(_selectedBackendKey);
  }

  /// Returns the saved backend type, or null if not yet configured
  BackendType? getSelectedBackend() {
    final value = _prefsInstance.getString(_selectedBackendKey);
    if (value == null) return null;
    for (final type in BackendType.values) {
      if (type.name == value) return type;
    }
    return null;
  }

  /// Persists the selected backend type
  Future<bool> saveSelectedBackend(BackendType type) async {
    return await _prefsInstance.setString(_selectedBackendKey, type.name);
  }

  /// Returns custom URL override saved for a specific backend
  String? getCustomBackendUrl(BackendType type) {
    return _prefsInstance.getString('$_customBackendUrlKeyPrefix${type.name}');
  }

  /// Saves custom URL override for a specific backend
  Future<bool> saveCustomBackendUrl(BackendType type, String? url) async {
    final key = '$_customBackendUrlKeyPrefix${type.name}';
    if (url == null || url.trim().isEmpty) {
      return await _prefsInstance.remove(key);
    }
    return await _prefsInstance.setString(key, url.trim());
  }

  // --- Scoped Key Helpers (Session per backend) ---
  String _tokenKey([BackendType? backend]) =>
      'userToken_${(backend ?? ApiConstants.activeBackend).name}';

  String _userKey([BackendType? backend]) =>
      'userModel_${(backend ?? ApiConstants.activeBackend).name}';

  String _idKey([BackendType? backend]) =>
      'userId_${(backend ?? ApiConstants.activeBackend).name}';

  String _loginKey([BackendType? backend]) =>
      'isLoggedIn_${(backend ?? ApiConstants.activeBackend).name}';

  // --- User Token ---
  Future<bool> saveUserToken(String? token, [BackendType? backend]) async {
    final key = _tokenKey(backend);
    if (token == null) {
      return await _prefsInstance.remove(key);
    }
    return await _prefsInstance.setString(key, token);
  }

  String? getUserToken([BackendType? backend]) {
    final key = _tokenKey(backend);
    return _prefsInstance.getString(key) ??
        // Fallback for backward compatibility
        _prefsInstance.getString(_legacyUserToken);
  }

  // --- User ID ---
  Future<bool> saveUserId(String? id, [BackendType? backend]) async {
    final key = _idKey(backend);
    if (id == null) {
      return await _prefsInstance.remove(key);
    }
    return await _prefsInstance.setString(key, id);
  }

  String? getUserId([BackendType? backend]) {
    final key = _idKey(backend);
    return _prefsInstance.getString(key) ??
        _prefsInstance.getString(_legacyUserId);
  }

  // --- Logged In Status ---
  Future<bool> saveIsLoggedIn(bool value, [BackendType? backend]) async {
    final key = _loginKey(backend);
    return await _prefsInstance.setBool(key, value);
  }

  bool isLoggedIn([BackendType? backend]) {
    final token = getUserToken(backend);
    final key = _loginKey(backend);
    return (token != null && token.isNotEmpty) ||
        (_prefsInstance.getBool(key) ??
            _prefsInstance.getBool(_legacyIsLoggedIn) ??
            false);
  }

  // --- User Model ---
  Future<bool> saveUserModel(UserModel? user, [BackendType? backend]) async {
    final key = _userKey(backend);
    if (user == null) {
      return await _prefsInstance.remove(key);
    }
    final String jsonStr = jsonEncode(user.toJson());
    return await _prefsInstance.setString(key, jsonStr);
  }

  UserModel? getUserModel([BackendType? backend]) {
    final key = _userKey(backend);
    final String? jsonStr = _prefsInstance.getString(key) ??
        _prefsInstance.getString(_legacyUserModel);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final Map<String, dynamic> map =
          jsonDecode(jsonStr) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  // --- Clear / Logout for Current Backend ---
  Future<void> clearAll([BackendType? backend]) async {
    await _prefsInstance.remove(_tokenKey(backend));
    await _prefsInstance.remove(_idKey(backend));
    await _prefsInstance.remove(_userKey(backend));
    await _prefsInstance.setBool(_loginKey(backend), false);

    // Also remove legacy keys to prevent ghost logins
    await _prefsInstance.remove(_legacyUserToken);
    await _prefsInstance.remove(_legacyUserId);
    await _prefsInstance.remove(_legacyUserModel);
    await _prefsInstance.setBool(_legacyIsLoggedIn, false);
  }
}

