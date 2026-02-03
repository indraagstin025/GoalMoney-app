import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/user.dart';
import '../services/fcm_service.dart'; // Import FCM Service

/// Status autentikasi user.
enum AuthStatus { authenticated, unauthenticated, loading }

/// Provider untuk mengelola proses autentikasi (Login, Register, Logout) dan sesi user.
class AuthProvider with ChangeNotifier {
  /// Instance ApiClient untuk komunikasi dengan backend.
  final ApiClient _apiClient = ApiClient();

  /// Status autentikasi saat ini, default adalah loading.
  AuthStatus _status = AuthStatus.loading;

  /// Data user yang sedang login.
  User? _user;

  /// Token JWT untuk autorisasi API.
  String? _token;

  AuthStatus get status => _status;
  User? get user => _user;

  /// Helper untuk mengecek apakah user sudah login.
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    // Jalankan pengecekan status login saat provider pertama kali diinisialisasi.
    checkLoginStatus();
  }

  /// Mengecek apakah ada token yang tersimpan di memori lokal (SharedPreferences).
  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');

    if (_token != null) {
      try {
        // Jika ada token, coba ambil data profil terbaru.
        await fetchProfile();
        _status = AuthStatus.authenticated;

        // Inisialisasi FCM (Firebase Cloud Messaging) untuk user yang sudah login.
        if (_user != null) {
          await FcmService().initialize(_user!.id);
          print('[AuthProvider] FCM diinisialisasi untuk user ${_user!.id}');
        }
      } catch (e) {
        // Jika gagal (misal token kadaluwarsa), anggap tidak terautentikasi.
        _status = AuthStatus.unauthenticated;
        await prefs.remove('token');
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Melakukan proses login ke sistem.
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

        // Simpan token ke memori lokal.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);

        _status = AuthStatus.authenticated;

        // Inisialisasi FCM setelah sukses login.
        await FcmService().initialize(_user!.id);
        print('[AuthProvider] FCM diinisialisasi untuk user ${_user!.id}');

        notifyListeners();
      }
    } on DioException catch (e) {
      // Menangani berbagai error HTTP dengan pesan Bahasa Indonesia yang ramah user.
      if (e.response?.statusCode == 401) {
        throw Exception('Email atau password salah');
      } else if (e.response?.statusCode == 422) {
        final message = e.response?.data['message'] ?? 'Data tidak valid';
        throw Exception(message);
      } else if (e.response?.statusCode == 500) {
        throw Exception(
          'Terjadi kesalahan pada server. Silakan coba lagi nanti',
        );
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Koneksi timeout. Periksa koneksi internet Anda');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Server tidak merespons. Silakan coba lagi');
      } else if (e.type == DioExceptionType.unknown) {
        throw Exception(
          'Tidak dapat terhubung ke server. Periksa koneksi internet Anda',
        );
      } else {
        final message =
            e.response?.data['message'] ?? 'Login gagal. Silakan coba lagi';
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan tidak terduga. Silakan coba lagi');
    }
  }

  /// Melakukan proses registrasi user baru.
  Future<void> register(String name, String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: {'name': name, 'email': email, 'password': password},
      );

      if (response.statusCode == 201) {
        // Langsung login otomatis setelah berhasil daftar.
        await login(email, password);
      }
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Registrasi gagal';
      throw Exception(message);
    }
  }

  /// Mengambil data profil user terbaru dari API.
  Future<void> fetchProfile() async {
    final response = await _apiClient.dio.get('/profile/user');
    if (response.statusCode == 200) {
      _user = User.fromJson(response.data['data']);
      notifyListeners();
    }
  }

  /// Menghapus sesi login dan membersihkan data dari memori lokal.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _token = null;
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Memperbarui profil ke server dan sinkronisasi ke state lokal.
  Future<void> updateProfile(String name, String email) async {
    try {
      final response = await _apiClient.dio.post(
        '/profile/update',
        data: {'name': name, 'email': email},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        _user = User(
          id: data['id'],
          name: data['name'],
          email: data['email'],
          availableBalance: _user?.availableBalance ?? 0,
        );

        // Update SharedPreferences untuk backup lokal
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_name', name);
        await prefs.setString('profile_email', email);

        notifyListeners();
      }
    } on DioException catch (e) {
      final message =
          e.response?.data['message'] ?? 'Gagal memperbarui profil di server';
      throw Exception(message);
    } catch (e) {
      throw Exception('Gagal memperbarui profil: $e');
    }
  }

  /// Memperbarui password user di server.
  Future<void> updatePassword(String oldPassword, String newPassword) async {
    try {
      final response = await _apiClient.dio.post(
        '/profile/update-password',
        data: {'old_password': oldPassword, 'new_password': newPassword},
      );

      if (response.statusCode == 200) {
        print('[AuthProvider] Password berhasil diperbarui di server');
      }
    } on DioException catch (e) {
      final message =
          e.response?.data['message'] ?? 'Gagal memperbarui password';
      throw Exception(message);
    } catch (e) {
      throw Exception('Gagal memperbarui password: $e');
    }
  }

  /// Memperbarui jumlah saldo tersedia milik user di dalam state.
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

  /// Memuat data profil yang disimpan secara lokal (override) jika ada.
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
      print('[AuthProvider] Overrides profil lokal dimuat');
    }
  }
}
