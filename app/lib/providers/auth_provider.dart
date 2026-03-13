import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/services.dart';
import '../utils/logger.dart';

/// Authentication Provider
/// 
/// Manages user authentication state and tokens
class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  
  bool _isLoggedIn = false;
  Map<String, dynamic>? _user;
  String? _error;
  bool _isLoading = false;

  AuthProvider({required ApiService apiService})
      : _apiService = apiService {
    _checkAuth();
  }

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get user => _user;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get hasError => _error != null;

  /// Check if user is already logged in
  Future<void> _checkAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token != null) {
        Logger.d('Found existing auth token', tag: 'Auth');
        _apiService.setAuthToken(token);

        // Backend doesn't expose a user profile endpoint yet.
        _user = {'username': 'admin'};
        _isLoggedIn = true;
        Logger.i('User authenticated from stored token', tag: 'Auth');
      }
    } catch (e, stackTrace) {
      Logger.e('Auth check failed', tag: 'Auth', error: e, stackTrace: stackTrace);
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      Logger.i('Login attempt for: $email', tag: 'Auth');
      final result = await _apiService.login(email, password);
      
      _user = result['user'] as Map<String, dynamic>;
      _isLoggedIn = true;
      
      // Save token
      final token = result['token'] as String;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      
      Logger.i('Login successful: ${_user?['username']}', tag: 'Auth');
      return true;
    } catch (e, stackTrace) {
      _error = e.toString();
      Logger.e('Login failed', tag: 'Auth', error: e, stackTrace: stackTrace);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update server URL before login
  Future<void> setServerUrl(String url) async {
    await ApiConfig.save(url);
    _apiService.updateBaseUrl(ApiConfig.baseUrl);

    // Clear any existing auth state
    _user = null;
    _isLoggedIn = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    notifyListeners();
  }

  /// Register new user
  Future<bool> register(String name, String email, String password) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      Logger.i('Registration attempt for: $email', tag: 'Auth');
      final result = await _apiService.register(name, email, password);
      
      _user = result['user'] as Map<String, dynamic>;
      _isLoggedIn = true;
      
      // Save token
      final token = result['token'] as String;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      
      Logger.i('Registration successful: ${_user?['email']}', tag: 'Auth');
      return true;
    } catch (e, stackTrace) {
      _error = e.toString();
      Logger.e('Registration failed', tag: 'Auth', error: e, stackTrace: stackTrace);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logout
  Future<void> logout() async {
    Logger.i('Logout', tag: 'Auth');
    
    _apiService.logout();
    _user = null;
    _isLoggedIn = false;
    _error = null;
    
    // Clear stored token
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
