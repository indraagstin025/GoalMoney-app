import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/transaction.dart';

class TransactionProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  List<Transaction> _transactions = [];
  bool _isLoading = false;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;

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
      print('Error fetching transactions: ${e.message}');
      _transactions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
        await fetchTransactions(goalId);
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to add transaction',
      );
    }
  }

  Future<void> deleteTransaction(int id, int goalId) async {
    try {
      await _apiClient.dio.delete('/transactions/delete', data: {'id': id});
      _transactions.removeWhere((t) => t.id == id);
      notifyListeners();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to delete transaction',
      );
    }
  }
}
