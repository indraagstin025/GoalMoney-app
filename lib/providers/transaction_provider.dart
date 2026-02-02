import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/transaction.dart';

/// Provider untuk mengelola state dan data transaksi tabungan.
class TransactionProvider with ChangeNotifier {
  /// Instance ApiClient untuk melakukan request ke API transaksi.
  final ApiClient _apiClient = ApiClient();

  /// Daftar transaksi untuk goal yang sedang dilihat.
  List<Transaction> _transactions = [];

  /// Status loading saat mengambil data transaksi.
  bool _isLoading = false;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;

  /// Mengambil riwayat transaksi untuk sebuah goal berdasarkan ID.
  Future<void> fetchTransactions(int goalId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.dio.get(
        '/transactions/index',
        queryParameters: {'goal_id': goalId},
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        _transactions = data.map((json) => Transaction.fromJson(json)).toList();
      }
    } on DioException catch (e) {
      print('Gagal mengambil data transaksi: ${e.message}');
      _transactions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Menambahkan transaksi (setoran) baru ke sebuah goal.
  Future<void> addTransaction({
    required int goalId,
    required double amount,
    String? description,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/transactions/store',
        data: {
          'goal_id': goalId,
          'amount': amount,
          if (description != null) 'description': description,
        },
      );

      if (response.statusCode == 201) {
        // Segarkan daftar transaksi setelah berhasil menambah data.
        await fetchTransactions(goalId);
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Gagal menambahkan transaksi',
      );
    }
  }

  /// Menghapus transaksi berdasarkan ID.
  Future<void> deleteTransaction(int id, int goalId) async {
    try {
      await _apiClient.dio.delete('/transactions/delete', data: {'id': id});
      _transactions.removeWhere((t) => t.id == id);
      notifyListeners();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Gagal menghapus transaksi',
      );
    }
  }

  /// Membersihkan seluruh data transaksi (saat logout).
  void clear() {
    _transactions = [];
    _isLoading = false;
    notifyListeners();
  }
}
