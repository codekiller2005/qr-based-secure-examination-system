import 'package:shared_preferences/shared_preferences.dart';
class StorageService {
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserRole = 'user_role';
  static const String _keyUserId = 'user_id';
  static const String _keyUsername = 'user_name';
  final SharedPreferences _prefs;
  StorageService(this._prefs);
  /// Saves the authenticated user session variables locally.
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String role,
    required String userId,
    required String username,
  }) async {
    await _prefs.setString(_keyAccessToken, accessToken);
    await _prefs.setString(_keyRefreshToken, refreshToken);
    await _prefs.setString(_keyUserRole, role);
    await _prefs.setString(_keyUserId, userId);
    await _prefs.setString(_keyUsername, username);
  }
  /// Getters for caching elements.
  String? get accessToken => _prefs.getString(_keyAccessToken);
  String? get refreshToken => _prefs.getString(_keyRefreshToken);
  String? get userRole => _prefs.getString(_keyUserRole);
  String? get userId => _prefs.getString(_keyUserId);
  String? get username => _prefs.getString(_keyUsername);
  /// Update the active access token (used during token refresh).
  Future<void> updateAccessToken(String token) async {
    await _prefs.setString(_keyAccessToken, token);
  }
  /// Clear session cache variables upon logout.
  Future<void> clearSession() async {
    await _prefs.remove(_keyAccessToken);
    await _prefs.remove(_keyRefreshToken);
    await _prefs.remove(_keyUserRole);
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyUsername);
  }
  /// Checks if there is an active session cache.
  bool get isLoggedIn => accessToken != null;
}
