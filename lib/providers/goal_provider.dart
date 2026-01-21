import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/goal.dart';
import '../models/withdrawal.dart';
import '../core/api_client.dart';
import '../core/photo_storage_service.dart';
import '../services/fcm_service.dart';

class GoalProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  List<Goal> _goals = [];
  Map<String, dynamic>? _dashboardSummary;
  bool _isLoading = false;

  // Withdrawal state
  WithdrawalSummary? _withdrawalSummary;
  List<Withdrawal> _withdrawals = [];
  
  // Notification state
  List<Map<String, dynamic>> _notifications = [];

  List<Goal> get goals => _goals;
  Map<String, dynamic>? get summary => _dashboardSummary;
  bool get isLoading => _isLoading;
  WithdrawalSummary? get withdrawalSummary => _withdrawalSummary;
  List<Withdrawal> get withdrawals => _withdrawals;
  List<Map<String, dynamic>> get notifications => _notifications;

  Future<void> fetchGoals() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.dio.get('/goals/index');
      if (response.statusCode == 200) {
        final List data = response.data['data'];
        _goals = data.map((json) => Goal.fromJson(json)).toList();
        print('[GoalProvider] Fetched ${_goals.length} goals');

        // Load photo paths for each goal
        for (var i = 0; i < _goals.length; i++) {
          try {
            final photoPath = await PhotoStorageService.getGoalPhotoPath(
              _goals[i].id,
            );
            print(
              '[GoalProvider] Goal ${_goals[i].id}: photoPath = $photoPath',
            );

            if (photoPath != null) {
              _goals[i] = Goal(
                id: _goals[i].id,
                name: _goals[i].name,
                targetAmount: _goals[i].targetAmount,
                currentAmount: _goals[i].currentAmount,
                deadline: _goals[i].deadline,
                description: _goals[i].description,
                progressPercentage: _goals[i].progressPercentage,
                photoPath: photoPath,
              );
            }
          } catch (e) {
            print(
              '[GoalProvider] Error loading photo for goal ${_goals[i].id}: $e',
            );
          }
        }
      }
    } catch (e) {
      print('[GoalProvider] Error fetching goals: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int?> createGoal({
    required String name,
    required double targetAmount,
    String? deadline,
    String? description,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/goals/store',
        data: {
          'name': name,
          'target_amount': targetAmount,
          if (deadline != null) 'deadline': deadline,
          if (description != null) 'description': description,
        },
      );

      if (response.statusCode == 201) {
        // Extract goal ID from response
        int? goalId;
        if (response.data['data'] != null &&
            response.data['data']['id'] != null) {
          goalId = response.data['data']['id'];
          print('[GoalProvider] New goal created with ID: $goalId');
        }

        await fetchGoals();
        await fetchDashboardSummary();
        return goalId;
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to create goal');
    }
    return null;
  }

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
      await fetchGoals();
      await fetchDashboardSummary();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update goal');
    }
  }

  Future<void> deleteGoal(int id) async {
    try {
      await _apiClient.dio.delete('/goals/delete', data: {'id': id});
      _goals.removeWhere((g) => g.id == id);
      await fetchDashboardSummary();
      notifyListeners();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete goal');
    }
  }

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
        await fetchGoals();
        await fetchDashboardSummary();
        
        // Return the data which may include overflow info
        return response.data['data'] ?? {};
      }
      throw Exception('Unexpected response');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to add transaction',
      );
    }
  }

  Future<Map<String, dynamic>> allocateOverflow({
    required List<Map<String, dynamic>> allocations,
    double? saveToBalanceAmount,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/transactions/allocate',
        data: {
          'allocations': allocations.map((a) => {
            ...a,
            'amount': (a['amount'] as num).toInt(),
          }).toList(),
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
      throw Exception('Unexpected response');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to allocate overflow',
      );
    }
  }

  Future<void> fetchDashboardSummary() async {
    try {
      final response = await _apiClient.dio.get('/dashboard/summary');
      if (response.statusCode == 200) {
        _dashboardSummary = response.data['data'];
        
        // Initialize Notification Service if user info is present
        if (_dashboardSummary != null && _dashboardSummary!.containsKey('user')) {
          try {
             final userId = _dashboardSummary!['user']['id'];
             await FcmService().initialize(userId);
             print('[GoalProvider] Notification service initialized for user $userId');
          } catch (e) {
             print('[GoalProvider] Failed to init notification service: $e');
          }
        }
        
        notifyListeners();
      }
    } on DioException catch (e) {
      print('Error fetching dashboard summary: ${e.message}');
    }
  }

  // ===== WITHDRAWAL METHODS =====

  /// Request withdrawal from a specific goal
  Future<void> requestWithdrawal({
    required int goalId,
    required double amount,
    required String method,
    String? accountNumber,
    String? notes,
  }) async {
    try {
      print('[GoalProvider] Requesting withdrawal of $amount from goal $goalId via $method');
      final response = await _apiClient.dio.post(
        '/withdrawals/request',
        data: {
          'goal_id': goalId,
          'amount': amount,
          'method': method,
          if (accountNumber != null) 'account_number': accountNumber,
          if (notes != null) 'notes': notes,
        },
      );

      if (response.statusCode == 201) {
        print('[GoalProvider] Withdrawal request created successfully');
        await fetchWithdrawalHistory();
        await fetchGoals(); // Refresh goals to update balances
        notifyListeners();
      }
    } on DioException catch (e) {
      print('[GoalProvider] Withdrawal error: ${e.response?.data}');
      throw Exception(
        e.response?.data['message'] ?? 'Failed to request withdrawal',
      );
    }
  }

  /// Get withdrawal history
  Future<void> fetchWithdrawalHistory({String? status}) async {
    try {
      print('[GoalProvider] Fetching withdrawal history');
      final Map<String, dynamic> queryParams = {};
      if (status != null) queryParams['status'] = status;

      final response = await _apiClient.dio.get(
        '/withdrawals/index',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];

        // Parse summary
        if (data['summary'] != null) {
          _withdrawalSummary = WithdrawalSummary.fromJson(data['summary']);
        }

        // Parse withdrawals
        if (data['withdrawals'] != null) {
          final List withdrawalList = data['withdrawals'];
          _withdrawals = withdrawalList
              .map((w) => Withdrawal.fromJson(w))
              .toList();
        }

        print('[GoalProvider] Fetched ${_withdrawals.length} withdrawals');
        notifyListeners();
      }
    } on DioException catch (e) {
      print('[GoalProvider] Error fetching withdrawals: ${e.message}');
      throw Exception(
        e.response?.data['message'] ?? 'Failed to fetch withdrawal history',
      );
    }
  }

  /// Get available balance for withdrawal
  double getAvailableBalance() {
    if (_withdrawalSummary == null) return 0;
    return _withdrawalSummary!.availableForWithdrawal;
  }

  /// Get total pending withdrawal
  double getTotalPendingWithdrawal() {
    if (_withdrawalSummary == null) return 0;
    return _withdrawalSummary!.totalPendingWithdrawal;
  }

  // ===== NOTIFICATION METHODS =====
  
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
      // Don't throw, just log so it doesn't crash UI
    }
  }
}
