import 'package:flutter/material.dart' hide Badge;
import 'package:dio/dio.dart';
import '../models/badge.dart';
import '../core/api_client.dart';

/// Provider untuk mengelola sistem Badge (Penghargaan) di dalam aplikasi.
/// Bertanggung jawab untuk mengambil data badge, mengecek pencapaian baru, dan menyimpan state badge.
class BadgeProvider extends ChangeNotifier {
  /// Instance ApiClient untuk komunikasi dengan backend.
  final ApiClient _apiClient = ApiClient();

  /// Daftar seluruh badge yang tersedia.
  List<Badge> _badges = [];

  /// Daftar badge yang sudah berhasil didapatkan oleh user.
  List<Badge> _earnedBadges = [];

  /// Daftar badge yang belum didapatkan.
  List<Badge> _unearnedBadges = [];

  /// Statistik ringkasan koleksi badge user.
  BadgeStats? _stats;

  /// Daftar badge yang baru saja didapatkan (untuk keperluan notifikasi/dialog).
  List<Badge> _newlyEarnedBadges = [];

  /// Status loading saat pengambilan data.
  bool _isLoading = false;

  /// Pesan error jika terjadi kendala saat fetching.
  String? _error;

  // Getters untuk akses data dari UI
  List<Badge> get badges => _badges;
  List<Badge> get earnedBadges => _earnedBadges;
  List<Badge> get unearnedBadges => _unearnedBadges;
  BadgeStats? get stats => _stats;
  List<Badge> get newlyEarnedBadges => _newlyEarnedBadges;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Mengambil daftar seluruh badge dan status pencapaian user dari API.
  Future<void> fetchBadges() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;

    // Bersihkan data lama segera agar UI tidak menampilkan data usang saat loading.
    _badges = [];
    _earnedBadges = [];
    _unearnedBadges = [];
    _stats = null;
    notifyListeners();

    print('[BadgeProvider] Mengambil data badge...');
    try {
      final response = await _apiClient.dio.get('/badges');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];

        final List<Badge> fetchedBadges = (data['badges'] as List)
            .map((b) => Badge.fromJson(b))
            .toList();

        _badges = fetchedBadges;
        _earnedBadges = _badges.where((b) => b.earned).toList();
        _unearnedBadges = _badges.where((b) => !b.earned).toList();
        _stats = BadgeStats.fromJson(data['stats']);

        print(
          '[BadgeProvider] Berhasil mengambil ${_badges.length} badge, ${_earnedBadges.length} sudah dimiliki',
        );
      }
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Gagal mengambil data badge';
      print('[BadgeProvider] Error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Memeriksa dan memberikan badge baru berdasarkan pencapaian terbaru user.
  /// Metode ini harus dipanggil setelah aksi penting seperti setoran, goal selesai, dll.
  Future<List<Badge>> checkAndAwardBadges() async {
    try {
      print('[BadgeProvider] Memeriksa pencapaian baru...');
      final response = await _apiClient.dio.post('/badges/check');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final newBadgesList = (data['new_badges'] as List)
            .map((b) => Badge.fromJson(b))
            .toList();

        if (newBadgesList.isNotEmpty) {
          _newlyEarnedBadges = newBadgesList;
          print(
            '[BadgeProvider] 🎉 Selamat! User mendapatkan ${newBadgesList.length} badge baru!',
          );

          // Segarkan daftar badge untuk menandai badge yang baru saja didapatkan.
          await fetchBadges();
          return newBadgesList;
        }
      }
    } on DioException catch (e) {
      print('[BadgeProvider] Error saat cek badge: ${e.message}');
    } catch (e) {
      print('[BadgeProvider] Error tidak terduga di checkAndAwardBadges: $e');
    }

    return [];
  }

  /// Membersihkan status badge baru yang sudah ditampilkan ke user.
  void clearNewlyEarnedBadges() {
    if (_newlyEarnedBadges.isNotEmpty) {
      _newlyEarnedBadges = [];
      notifyListeners();
    }
  }

  /// Mencari data badge berdasarkan kode sistem.
  Badge? getBadgeByCode(String code) {
    try {
      return _badges.firstWhere((b) => b.code == code);
    } catch (e) {
      return null;
    }
  }

  /// Membersihkan seluruh data state badge (saat logout).
  void clear() {
    _badges = [];
    _earnedBadges = [];
    _unearnedBadges = [];
    _stats = null;
    _newlyEarnedBadges = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
