import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/user.dart';
import '../services/fcm_service.dart'; // Import FCM Service

enum AuthStatus { authenticated, unauthenticated, loading }

class AuthProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  AuthStatus _status = AuthStatus.loading;
  User? _user;
  String? _token;

  AuthStatus get status => _status;
  User? get user => _user;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');

    // Artificial delay for splash screen visibility (3 seconds)
    await Future.delayed(const Duration(seconds: 3));

    if (_token != null) {
      try {
        await fetchProfile();
        _status = AuthStatus.authenticated;
        
        // Initialize FCM for returning user
        if (_user != null) {
          await FcmService().initialize(_user!.id);
          print('[AuthProvider] FCM initialized for returning user ${_user!.id}');
        }
      } catch (e) {
        _status = AuthStatus.unauthenticated;
        await prefs.remove('token');
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        _token = data['token'];

        _user = User.fromJson(data['user']);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);

        _status = AuthStatus.authenticated;
        
        // Initialize FCM after successful login
        await FcmService().initialize(_user!.id);
        print('[AuthProvider] FCM initialized for user ${_user!.id}');
        
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> register(String name, String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: {'name': name, 'email': email, 'password': password},
      );

      if (response.statusCode == 201) {
        // Auto-login after successful registration
        await login(email, password);
      }
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Registration failed';
      throw Exception(message);
    }
  }

  Future<void> fetchProfile() async {
    final response = await _apiClient.dio.get('/profile/user');
    if (response.statusCode == 200) {
      _user = User.fromJson(response.data['data']);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _token = null;
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Update profile locally using SharedPreferences
  Future<void> updateProfile(String? name, String? email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Update local storage
      if (name != null) {
        await prefs.setString('profile_name', name);
      }
      if (email != null) {
        await prefs.setString('profile_email', email);
      }
      
      // Update user object with new values
      if (_user != null) {
        _user = User(
          id: _user!.id,
          name: name ?? _user!.name,
          email: email ?? _user!.email,
          availableBalance: _user!.availableBalance,
        );
        notifyListeners();
      }
      
      print('[AuthProvider] Profile updated locally: name=$name, email=$email');
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  void setAvailableBalance(double amount) {
    if (_user != null) {
      _user = User(
        id: _user!.id,
        name: _user!.name,
        email: _user!.email,
        availableBalance: amount,
      );
      notifyListeners();
    }
  }
  
  /// Load locally saved profile overrides
  Future<void> _loadLocalProfileOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('profile_name');
    final savedEmail = prefs.getString('profile_email');
    
    if (_user != null && (savedName != null || savedEmail != null)) {
      _user = User(
        id: _user!.id,
        name: savedName ?? _user!.name,
        email: savedEmail ?? _user!.email,
        availableBalance: _user!.availableBalance,
      );
      print('[AuthProvider] Loaded local profile overrides');
    }
  }
}
