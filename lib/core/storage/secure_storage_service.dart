import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  final FlutterSecureStorage _secureStorage;

  SecureStorageService([FlutterSecureStorage? secureStorage])
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'auth_jwt_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _activeBusinessIdKey = 'active_business_id';
  static const String _isLoggedInKey = 'is_logged_in';

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _secureStorage.write(key: _tokenKey, value: accessToken);
    if (refreshToken != null) {
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  Future<void> setActiveBusinessId(int businessId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_activeBusinessIdKey, businessId);
  }

  Future<int?> getActiveBusinessId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_activeBusinessIdKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
