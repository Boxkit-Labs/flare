import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ghost_app/core/config/app_constants.dart';
import 'package:ghost_app/core/models/models.dart';

/// Central API service for communicating with the Flare backend.
/// Uses Dio with interceptors for logging and error handling.
class ApiService {
  late final Dio _dio;

  /// The current authenticated user's ID. Set after registration/login.
  String? userId;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Add logging interceptor in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => debugPrint('[API] $obj'),
        ),
      );
    }
  }

  // ─── USER METHODS ──────────────────────────────────────────

  /// Register a new user with the given device ID.
  Future<UserModel> register(String deviceId) async {
    final response = await _dio.post(
      '/api/users/register',
      data: {'device_id': deviceId},
    );
    final user = UserModel.fromJson(response.data);
    userId = user.userId;
    return user;
  }

  /// Fund the user's Stellar wallet via the Operator account.
  Future<Map<String, dynamic>> fundWallet(String userId) async {
    final response = await _dio.post('/api/users/$userId/fund');
    return Map<String, dynamic>.from(response.data);
  }

  /// Update the user's FCM push notification token.
  Future<void> updateFcmToken(String userId, String token) async {
    await _dio.post(
      '/api/users/$userId/fcm-token',
      data: {'fcm_token': token},
    );
  }

  /// Update user settings (briefing_time, timezone, dnd, etc.).
  Future<void> updateSettings(
      String userId, Map<String, dynamic> settings) async {
    await _dio.put('/api/users/$userId/settings', data: settings);
  }

  /// Get a user by ID.
  Future<UserModel> getUser(String userId) async {
    final response = await _dio.get('/api/users/$userId');
    return UserModel.fromJson(response.data);
  }

  // ─── WATCHER METHODS ───────────────────────────────────────

  /// Create a new watcher.
  Future<WatcherModel> createWatcher(Map<String, dynamic> watcher) async {
    final response = await _dio.post('/api/watchers', data: watcher);
    return WatcherModel.fromJson(response.data);
  }

  /// List all watchers for a given user.
  Future<List<WatcherModel>> getWatchers(String userId) async {
    final response =
        await _dio.get('/api/watchers', queryParameters: {'user_id': userId});
    final list = response.data as List;
    return list.map((w) => WatcherModel.fromJson(w)).toList();
  }

  /// Get a single watcher with recent checks and findings.
  Future<WatcherModel> getWatcher(String watcherId) async {
    final response = await _dio.get('/api/watchers/$watcherId');
    return WatcherModel.fromJson(response.data);
  }

  /// Update specific fields on a watcher.
  Future<WatcherModel> updateWatcher(
      String watcherId, Map<String, dynamic> fields) async {
    final response = await _dio.put('/api/watchers/$watcherId', data: fields);
    return WatcherModel.fromJson(response.data);
  }

  /// Toggle a watcher between active and paused_manual.
  Future<WatcherModel> toggleWatcher(String watcherId) async {
    final response = await _dio.post('/api/watchers/$watcherId/toggle');
    return WatcherModel.fromJson(response.data);
  }

  /// Delete a watcher.
  Future<void> deleteWatcher(String watcherId) async {
    await _dio.delete('/api/watchers/$watcherId');
  }

  // ─── FINDING METHODS ───────────────────────────────────────

  /// List findings for a user with optional pagination.
  Future<List<FindingModel>> getFindings(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _dio.get('/api/findings', queryParameters: {
      'user_id': userId,
      'limit': limit,
      'offset': offset,
    });
    final list = response.data as List;
    return list.map((f) => FindingModel.fromJson(f)).toList();
  }

  /// Get a single finding with full detail.
  Future<FindingModel> getFinding(String findingId) async {
    final response = await _dio.get('/api/findings/$findingId');
    return FindingModel.fromJson(response.data);
  }

  /// Mark a finding as read.
  Future<void> markFindingRead(String findingId) async {
    await _dio.post('/api/findings/$findingId/read');
  }

  // ─── BRIEFING METHODS ──────────────────────────────────────

  /// List recent briefings for a user.
  Future<List<BriefingModel>> getBriefings(
    String userId, {
    int limit = 7,
  }) async {
    final response = await _dio.get('/api/briefings', queryParameters: {
      'user_id': userId,
      'limit': limit,
    });
    final list = response.data as List;
    return list.map((b) => BriefingModel.fromJson(b)).toList();
  }

  /// Get today's briefing for a user.
  Future<BriefingModel?> getTodayBriefing(String userId) async {
    final response = await _dio.get('/api/briefings/today', queryParameters: {
      'user_id': userId,
    });
    if (response.data == null) return null;
    return BriefingModel.fromJson(response.data);
  }

  /// Manually generate a briefing for a user.
  Future<BriefingModel> generateBriefing(String userId) async {
    final response = await _dio.post(
      '/api/briefings/generate',
      data: {'user_id': userId},
    );
    return BriefingModel.fromJson(response.data);
  }

  // ─── WALLET METHODS ────────────────────────────────────────

  /// Get wallet balances (USDC + XLM).
  Future<WalletModel> getWallet(String userId) async {
    final response = await _dio.get('/api/wallet/$userId');
    return WalletModel.fromJson(response.data);
  }

  /// Get spending analytics and stats.
  Future<SpendingStatsModel> getWalletStats(String userId) async {
    final response = await _dio.get('/api/wallet/$userId/stats');
    return SpendingStatsModel.fromJson(response.data);
  }

  // ─── TRANSACTION METHODS ───────────────────────────────────

  /// List transactions for a user with optional pagination.
  Future<List<TransactionModel>> getTransactions(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _dio.get('/api/transactions', queryParameters: {
      'user_id': userId,
      'limit': limit,
      'offset': offset,
    });
    final list = response.data as List;
    return list.map((t) => TransactionModel.fromJson(t)).toList();
  }

  /// List transactions for a specific watcher.
  Future<List<TransactionModel>> getTransactionsByWatcher(
    String watcherId, {
    int limit = 20,
  }) async {
    final response = await _dio.get('/api/transactions', queryParameters: {
      'watcher_id': watcherId,
      'limit': limit,
    });
    final list = response.data as List;
    return list.map((t) => TransactionModel.fromJson(t)).toList();
  }
}
