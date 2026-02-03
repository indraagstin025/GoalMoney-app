import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/goal.dart';
import '../models/withdrawal.dart';
import '../models/report.dart';
import '../core/api_client.dart';
import '../core/photo_storage_service.dart';
import '../services/fcm_service.dart';

/// Provider utama untuk mengelola state dan logika bisnis terkait Goal (Target Tabungan).
/// Menggunakan [ChangeNotifier] untuk memberitahu UI saat data berubah.
class GoalProvider with ChangeNotifier {
  /// Instance ApiClient untuk melakukan request HTTP ke backend PHP.
  final ApiClient _apiClient = ApiClient();

  /// Daftar seluruh goal milik user yang sedang login.
  List<Goal> _goals = [];

  /// Data ringkasan (summary) untuk ditampilkan di Dashboard.
  Map<String, dynamic>? _dashboardSummary;

  /// Status loading umum untuk operasi fetching data.
  bool _isLoading = false;

  // State terkait Penarikan (Withdrawal)
  /// Ringkasan saldo dan status penarikan.
  WithdrawalSummary? _withdrawalSummary;

  /// Riwayat penarikan dana.
  List<Withdrawal> _withdrawals = [];

  // State terkait Notifikasi
  /// Daftar pesan notifikasi terbaru.
  List<Map<String, dynamic>> _notifications = [];

  // State terkait Laporan (Report)
  /// Objek laporan tabungan lengkap.
  SavingsReport? _report;

  /// Status loading khusus untuk fetching laporan.
  bool _isLoadingReport = false;

  // State terkait Prediksi (Forecast)
  /// Daftar estimasi waktu pencapaian goal.
  List<Map<String, dynamic>> _forecasts = [];

  /// Status loading khusus untuk fetching prediksi.
  bool _isLoadingForecast = false;

  // Getters untuk akses data dari UI
  List<Goal> get goals => _goals;
  Map<String, dynamic>? get summary => _dashboardSummary;
  bool get isLoading => _isLoading;
  WithdrawalSummary? get withdrawalSummary => _withdrawalSummary;
  List<Withdrawal> get withdrawals => _withdrawals;
  List<Map<String, dynamic>> get notifications => _notifications;
  SavingsReport? get report => _report;
  bool get isLoadingReport => _isLoadingReport;
  List<Map<String, dynamic>> get forecasts => _forecasts;
  bool get isLoadingForecast => _isLoadingForecast;

  /// Mengambil daftar goal dari API dan memuat foto lokal secara paralel.
  Future<void> fetchGoals() async {
    _isLoading = true;
    _goals = []; // Bersihkan data lama
    notifyListeners();
    try {
      final response = await _apiClient.dio.get('/goals/index');
      if (response.statusCode == 200) {
        final List data = response.data['data'];
        final tempGoals = data.map((json) => Goal.fromJson(json)).toList();

        print(
          '[GoalProvider] Berhasil mengambil ${tempGoals.length} goal. Memuat gambar...',
        );

        // Memuat path foto lokal secara paralel untuk meningkatkan performa
        final goalsWithPhotos = await Future.wait(
          tempGoals.map((goal) async {
            try {
              final photoPath = await PhotoStorageService.getGoalPhotoPath(
                goal.id,
              );
              if (photoPath != null) {
                return Goal(
                  id: goal.id,
                  name: goal.name,
                  targetAmount: goal.targetAmount,
                  currentAmount: goal.currentAmount,
                  deadline: goal.deadline,
                  description: goal.description,
                  progressPercentage: goal.progressPercentage,
                  photoPath: photoPath,
                  type: goal.type,
                  createdAt: goal.createdAt,
                );
              }
            } catch (e) {
              print(
                '[GoalProvider] Gagal memuat foto untuk goal ${goal.id}: $e',
              );
            }
            return goal;
          }),
        );

        _goals = goalsWithPhotos;
      }
    } catch (e) {
      print('[GoalProvider] Error saat fetchGoals: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Membuat goal baru di database.
  /// Mengembalikan ID goal jika berhasil, atau null jika gagal.
  Future<int?> createGoal({
    required String name,
    required double targetAmount,
    String? deadline,
    String? description,
    String type = 'digital',
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/goals/store',
        data: {
          'name': name,
          'target_amount': targetAmount,
          'type': type,
          if (deadline != null) 'deadline': deadline,
          if (description != null) 'description': description,
        },
      );

      if (response.statusCode == 201) {
        int? goalId;
        if (response.data['data'] != null &&
            response.data['data']['id'] != null) {
          goalId = response.data['data']['id'];
          print('[GoalProvider] Goal baru dibuat dengan ID: $goalId');
        }

        // Segarkan data dashboard dan daftar goal secara paralel
        await Future.wait([fetchGoals(), fetchDashboardSummary()]);

        return goalId;
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal membuat goal');
    }
    return null;
  }

  /// Memperbarui data goal yang sudah ada.
  Future<void> updateGoal({
    required int id,
    String? name,
    double? targetAmount,
    String? deadline,
    String? description,
  }) async {
    try {
      final data = <String, dynamic>{'id': id};
      if (name != null) data['name'] = name;
      if (targetAmount != null) data['target_amount'] = targetAmount;
      if (deadline != null) data['deadline'] = deadline;
      if (description != null) data['description'] = description;

      await _apiClient.dio.put('/goals/update', data: data);

      // Segarkan data dashboard dan daftar goal secara paralel
      await Future.wait([fetchGoals(), fetchDashboardSummary()]);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal memperbarui goal');
    }
  }

  /// Menghapus goal berdasarkan ID.
  Future<void> deleteGoal(int id) async {
    try {
      await _apiClient.dio.delete('/goals/delete', data: {'id': id});
      _goals.removeWhere((g) => g.id == id);
      await fetchDashboardSummary();
      notifyListeners();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal menghapus goal');
    }
  }

  /// Menambahkan setoran uangan (transaksi) ke sebuah goal.
  /// Mengembalikan data respons (yang mungkin berisi info overflow saldo).
  Future<Map<String, dynamic>> addTransaction({
    required int goalId,
    required double amount,
    String method = 'manual',
    String? description,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/transactions/store',
        data: {
          'goal_id': goalId,
          'amount': amount,
          'method': method,
          if (description != null) 'description': description,
        },
      );

      if (response.statusCode == 201) {
        // Segarkan data secara paralel
        await Future.wait([fetchGoals(), fetchDashboardSummary()]);

        return response.data['data'] ?? {};
      }

      throw Exception('Respons tidak terduga');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Gagal menambahkan transaksi',
      );
    }
  }

  /// Mengalokasikan kelebihan saldo (overflow) ke goal lain atau simpan ke saldo tersedia.
  Future<Map<String, dynamic>> allocateOverflow({
    required List<Map<String, dynamic>> allocations,
    double? saveToBalanceAmount,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/transactions/allocate',
        data: {
          'allocations': allocations
              .map((a) => {...a, 'amount': (a['amount'] as num).toInt()})
              .toList(),
          if (saveToBalanceAmount != null) ...{
            'save_to_balance_amount': saveToBalanceAmount.toInt(),
            'save_remaining_as_balance': true,
          },
        },
      );

      if (response.statusCode == 200) {
        await fetchGoals();
        await fetchDashboardSummary();

        return response.data['data'] ?? {};
      }
      throw Exception('Respons tidak terduga');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Gagal mengalokasikan overflow',
      );
    }
  }

  /// Mengambil data ringkasan untuk dashboard (total saldo, target, user info, dll).
  Future<void> fetchDashboardSummary() async {
    _isLoading = true;
    _dashboardSummary = null; // Bersihkan data lama
    notifyListeners();
    try {
      final response = await _apiClient.dio.get('/dashboard/summary');
      if (response.statusCode == 200) {
        _dashboardSummary = response.data['data'];

        // Inisialisasi Layanan Notifikasi Firebase jika data user tersedia
        if (_dashboardSummary != null &&
            _dashboardSummary!.containsKey('user')) {
          try {
            final userId = _dashboardSummary!['user']['id'];
            await FcmService().initialize(userId);
            print(
              '[GoalProvider] Layanan notifikasi diinisialisasi untuk user $userId',
            );
          } catch (e) {
            print(
              '[GoalProvider] Gagal menginisialisasi layanan notifikasi: $e',
            );
          }
        }
      }
    } on DioException catch (e) {
      print('Gagal mengambil summary dashboard: ${e.message}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===== METODE PENARIKAN (WITHDRAWAL) =====

  /// Mengajukan permintaan penarikan dari goal tertentu atau saldo tersedia.
  Future<void> requestWithdrawal({
    int? goalId,
    required double amount,
    required String method,
    String? accountNumber,
    String? notes,
  }) async {
    try {
      print(
        '[GoalProvider] Meminta penarikan sebesar $amount dari ${goalId != null ? "goal $goalId" : "Saldo Tersedia"} melalui $method',
      );
      final response = await _apiClient.dio.post(
        '/withdrawals/request',
        data: {
          if (goalId != null) 'goal_id': goalId,
          'amount': amount,
          'method': method,
          if (accountNumber != null) 'account_number': accountNumber,
          if (notes != null) 'notes': notes,
        },
      );

      if (response.statusCode == 201) {
        print('[GoalProvider] Permintaan penarikan berhasil dibuat');
        await fetchWithdrawalHistory();
        await fetchGoals(); // Refresh goal untuk memperbarui saldo
        notifyListeners();
      }
    } on DioException catch (e) {
      print('[GoalProvider] Error penarikan: ${e.response?.data}');
      throw Exception(
        e.response?.data['message'] ?? 'Gagal mengajukan penarikan',
      );
    }
  }

  /// Mengambil riwayat penarikan dana.
  Future<void> fetchWithdrawalHistory({String? status}) async {
    _isLoading = true;
    notifyListeners();
    try {
      print('[GoalProvider] Mengambil riwayat penarikan');
      final Map<String, dynamic> queryParams = {};
      if (status != null) queryParams['status'] = status;

      final response = await _apiClient.dio.get(
        '/withdrawals/index',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];

        // Parsing ringkasan penarikan
        if (data['summary'] != null) {
          _withdrawalSummary = WithdrawalSummary.fromJson(data['summary']);
        }

        // Parsing daftar penarikan
        if (data['withdrawals'] != null) {
          final List withdrawalList = data['withdrawals'];
          _withdrawals = withdrawalList
              .map((w) => Withdrawal.fromJson(w))
              .toList();
        }

        print(
          '[GoalProvider] Berhasil mengambil ${_withdrawals.length} riwayat penarikan',
        );
      }
    } on DioException catch (e) {
      print('[GoalProvider] Error saat mengambil penarikan: ${e.message}');
      throw Exception(
        e.response?.data['message'] ?? 'Gagal mengambil riwayat penarikan',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mendapatkan saldo yang tersedia untuk ditarik.
  double getAvailableBalance() {
    if (_withdrawalSummary == null) return 0;
    return _withdrawalSummary!.availableForWithdrawal;
  }

  /// Mendapatkan total dana yang sedang menunggu proses penarikan.
  double getTotalPendingWithdrawal() {
    if (_withdrawalSummary == null) return 0;
    return _withdrawalSummary!.totalPendingWithdrawal;
  }

  // ===== METODE NOTIFIKASI (NOTIFICATION) =====

  /// Mengambil daftar notifikasi terbaru user.
  Future<void> fetchNotifications() async {
    try {
      final response = await _apiClient.dio.get('/notifications/index');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'];
        _notifications = List<Map<String, dynamic>>.from(data);
        notifyListeners();
      }
    } on DioException catch (e) {
      print('[GoalProvider] Error fetching notifications: ${e.response?.data}');
    }
  }

  // ===== METODE LAPORAN (REPORT) =====

  /// Mengambil laporan tabungan lengkap dari API dengan filter opsional.
  Future<void> fetchReport({
    String? startDate,
    String? endDate,
    String? searchQuery,
  }) async {
    _isLoadingReport = true;
    notifyListeners();

    try {
      final Map<String, dynamic> queryParams = {};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }

      print('[GoalProvider] Mengambil laporan tabungan dengan filter...');
      final response = await _apiClient.dio.get(
        '/reports/report',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        _report = SavingsReport.fromJson(response.data['data']);
        print('[GoalProvider] Laporan berhasil diambil');
      }
    } on DioException catch (e) {
      print('[GoalProvider] Error saat mengambil laporan: ${e.response?.data}');
      throw Exception(e.response?.data['message'] ?? 'Gagal mengambil laporan');
    } finally {
      _isLoadingReport = false;
      notifyListeners();
    }
  }

  /// Menghapus data laporan dari cache (biasanya saat keluar halaman).
  void clearReport() {
    _report = null;
    notifyListeners();
  }

  /// Mengambil data prediksi/estimasi pencapaian goal.
  Future<void> fetchForecasts({int? goalId}) async {
    _isLoadingForecast = true;
    notifyListeners();

    try {
      final Map<String, dynamic> queryParams = {};
      if (goalId != null) queryParams['goal_id'] = goalId;

      final response = await _apiClient.dio.get(
        '/goals/forecast',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'];
        _forecasts = List<Map<String, dynamic>>.from(data);
      }
    } on DioException catch (e) {
      print(
        '[GoalProvider] Error saat mengambil prediksi: ${e.response?.data}',
      );
    } finally {
      _isLoadingForecast = false;
      notifyListeners();
    }
  }

  /// Mendapatkan data prediksi khusus untuk satu goal berdasarkan ID.
  Map<String, dynamic>? getForecastForGoal(int goalId) {
    try {
      return _forecasts.firstWhere((f) => f['goal_id'] == goalId);
    } catch (_) {
      return null;
    }
  }

  /// Membersihkan seluruh data state (digunakan saat logout).
  void clear() {
    _goals = [];
    _dashboardSummary = null;
    _withdrawalSummary = null;
    _withdrawals = [];
    _notifications = [];
    _report = null;
    _forecasts = [];
    _isLoading = false;
    _isLoadingReport = false;
    _isLoadingForecast = false;
    notifyListeners();
  }
}
