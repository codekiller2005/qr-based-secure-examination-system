import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;
  bool _isLoading = false;
  String? _errorMessage;
  String? _username;
  String? _role;
  AuthProvider(this._apiService, this._storageService) {
    _restoreSession();
  }
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get username => _username;
  String? get role => _role;
  bool get isAuthenticated => _storageService.isLoggedIn;
  /// Restores cached login session details on app startup.
  void _restoreSession() {
    if (_storageService.isLoggedIn) {
      _username = _storageService.username;
      _role = _storageService.userRole;
    }
  }
  /// Handles multi-role login routing, session storage, and notifies listeners (Mocked).
  Future<bool> login(String username, String password, String selectedRole) async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    String loginEndpoint;

    if (selectedRole == 'student') {
      loginEndpoint = ApiEndpoints.studentLogin;
    } else if (selectedRole == 'invigilator') {
      loginEndpoint = ApiEndpoints.invigilatorLogin;
    } else {
      loginEndpoint = ApiEndpoints.login;
    }

    final response = await _apiService.dio.post(
      loginEndpoint,
      data: {
        'username': username,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      print("LOGIN RESPONSE = ${response.data}");
      final data = response.data as Map<String, dynamic>;

      await _storageService.saveSession(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
        role: data['role'],
        userId: '',
        username: username,
      );

      _role = data['role'];
      _username = username;

      _isLoading = false;
      notifyListeners();
      return true;
    }
  } on DioException catch (e) {
    print("DIO ERROR = ${e.message}");
    print("DIO STATUS = ${e.response?.statusCode}");
    print("DIO RESPONSE = ${e.response?.data}");
    if (e.response?.data != null &&
        e.response!.data is Map &&
        e.response!.data.containsKey('detail')) {
      _errorMessage = e.response!.data['detail'].toString();
    } else {
      _errorMessage = 'Login failed';
    }
  } catch (e) {
    _errorMessage = e.toString();
  }

  _isLoading = false;
  notifyListeners();
  return false;
}
  /// Resolves the user profile ID dynamically using active tokens (Mocked).
  Future<void> _fetchUserProfile() async {
    // No-op for mock login authentication
  }
  /// Clears session caches and notifies widgets to redirect to login.
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _storageService.clearSession();
    _username = null;
    _role = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}