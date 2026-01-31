// lib/providers/badge_provider.dart
// Provider untuk state management Badge system

import 'package:flutter/material.dart' hide Badge;
import 'package:dio/dio.dart';
import '../models/badge.dart';
import '../core/api_client.dart';

class BadgeProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<Badge> _badges = [];
  List<Badge> _earnedBadges = [];
  List<Badge> _unearnedBadges = [];
  BadgeStats? _stats;
  List<Badge> _newlyEarnedBadges = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Badge> get badges => _badges;
  List<Badge> get earnedBadges => _earnedBadges;
  List<Badge> get unearnedBadges => _unearnedBadges;
  BadgeStats? get stats => _stats;
  List<Badge> get newlyEarnedBadges => _newlyEarnedBadges;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all badges and user's earned badges
  Future<void> fetchBadges() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    // Clear existing data immediately to avoid stale data during loading
    _badges = [];
    _earnedBadges = [];
    _unearnedBadges = [];
    _stats = null;
    notifyListeners();

    print('[BadgeProvider] Fetching badges... (isLoading: $_isLoading)');
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
          '[BadgeProvider] Fetched ${_badges.length} badges, ${_earnedBadges.length} earned',
        );
      }
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Failed to fetch badges';
      print('[BadgeProvider] Error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check and award new badges based on user's achievements
  /// This should be called after important user actions (deposit, goal completion, etc)
  Future<List<Badge>> checkAndAwardBadges() async {
    try {
      print('[BadgeProvider] Checking for new achievements...');
      final response = await _apiClient.dio.post('/badges/check');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final newBadgesList = (data['new_badges'] as List)
            .map((b) => Badge.fromJson(b))
            .toList();

        if (newBadgesList.isNotEmpty) {
          _newlyEarnedBadges = newBadgesList;
          print(
            '[BadgeProvider] 🎉 HURRAY! Awarded ${newBadgesList.length} new badges!',
          );

          // Refresh the list to mark badges as earned
          await fetchBadges();
          return newBadgesList;
        }
      }
    } on DioException catch (e) {
      print('[BadgeProvider] Error checking badges: ${e.message}');
    } catch (e) {
      print('[BadgeProvider] Unexpected error in checkAndAwardBadges: $e');
    }

    return [];
  }

  /// Clear newly earned badges state
  void clearNewlyEarnedBadges() {
    if (_newlyEarnedBadges.isNotEmpty) {
      _newlyEarnedBadges = [];
      notifyListeners();
    }
  }

  /// Get badge by code
  Badge? getBadgeByCode(String code) {
    try {
      return _badges.firstWhere((b) => b.code == code);
    } catch (e) {
      return null;
    }
  }

  /// Clear all badge data (on logout)
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
