import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flare_app/core/config/app_constants.dart';
import 'package:flare_app/core/models/models.dart';
import 'package:flare_app/core/models/notification_model.dart';
import 'package:flare_app/core/error/exceptions.dart';

class ApiService {
  late final Dio _dio;
  String? userId;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Content-Type': 'application/json'},

      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => debugPrint('[API] $obj'),
        ),
      );
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, handler) {
          final appException = mapDioException(e);
          return handler.next(DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            type: e.type,
            error: appException,
            message: appException.message,
          ));
        },
      ),
    );
  }

  Future<bool> checkHealth() async {
    int attempts = 0;
    while (attempts < 3) {
      try {
        attempts++;
        final response = await _dio.get('/health', options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ));
        return response.statusCode == 200;
      } catch (e) {
        debugPrint('ApiService: Health check attempt $attempts failed: $e');
        if (attempts >= 3) break;
        await Future.delayed(const Duration(seconds: 5));
      }
    }

    return false;
  }

  Future<UserModel> register(String deviceId) async {
    final response = await _dio.post(
      '/api/users/register',
      data: {'device_id': deviceId},
    );
    final user = UserModel.fromJson(response.data);
    userId = user.userId;
    return user;
  }

  Future<Map<String, dynamic>> fundWallet(String userId) async {
    final response = await _dio.post(
      '/api/users/$userId/fund',
      options: Options(receiveTimeout: const Duration(seconds: 60)),
    );
    return Map<String, dynamic>.from(response.data);
  }

  Future<void> updateFcmToken(String userId, String token) async {
    await _dio.post(
      '/api/users/$userId/fcm-token',
      data: {'fcm_token': token},
    );
  }

  Future<void> updateSettings(
      String userId, Map<String, dynamic> settings) async {
    await _dio.put('/api/users/$userId/settings', data: settings);
  }

  Future<UserModel> getUser(String userId) async {
    final response = await _dio.get('/api/users/$userId');
    return UserModel.fromJson(response.data);
  }

  Future<WatcherModel> createWatcher(Map<String, dynamic> watcher) async {
    final response = await _dio.post('/api/watchers', data: watcher);
    return WatcherModel.fromJson(response.data);
  }

  Future<List<WatcherModel>> getWatchers(String userId) async {
    final response =
        await _dio.get('/api/watchers', queryParameters: {'user_id': userId});
    final list = response.data as List;
    return list.map((w) => WatcherModel.fromJson(w)).toList();
  }

  Future<WatcherModel> getWatcher(String watcherId) async {
    final response = await _dio.get('/api/watchers/$watcherId');
    return WatcherModel.fromJson(response.data);
  }

  Future<WatcherModel> updateWatcher(
      String watcherId, Map<String, dynamic> fields) async {
    final response = await _dio.put('/api/watchers/$watcherId', data: fields);
    return WatcherModel.fromJson(response.data);
  }

  Future<WatcherModel> toggleWatcher(String watcherId) async {
    final response = await _dio.post('/api/watchers/$watcherId/toggle');
    return WatcherModel.fromJson(response.data);
  }

  Future<void> deleteWatcher(String watcherId) async {
    await _dio.delete('/api/watchers/$watcherId');
  }

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

  Future<FindingModel> getFinding(String findingId) async {
    final response = await _dio.get('/api/findings/$findingId');
    return FindingModel.fromJson(response.data);
  }

  Future<void> markFindingRead(String findingId) async {
    await _dio.post('/api/findings/$findingId/read');
  }

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

  Future<BriefingModel?> getTodayBriefing(String userId) async {
    final response = await _dio.get('/api/briefings/today', queryParameters: {
      'user_id': userId,
    });
    if (response.data == null) return null;
    return BriefingModel.fromJson(response.data);
  }

  Future<BriefingModel?> getBriefingByDate(String userId, String date) async {
    final response = await _dio.get('/api/briefings/by-date', queryParameters: {
      'user_id': userId,
      'date': date,
    });
    if (response.data == null) return null;
    return BriefingModel.fromJson(response.data);
  }

  Future<BriefingModel> generateBriefing(String userId) async {
    final response = await _dio.post(
      '/api/briefings/generate',
      data: {'user_id': userId},
    );
    return BriefingModel.fromJson(response.data);
  }

  Future<void> markBriefingRead(String briefingId) async {
    await _dio.post('/api/briefings/$briefingId/read');
  }

  Future<WalletModel> getWallet(String userId) async {
    final response = await _dio.get('/api/wallet/$userId');
    return WalletModel.fromJson(response.data);
  }

  Future<SpendingStatsModel> getWalletStats(String userId) async {
    final response = await _dio.get('/api/wallet/$userId/stats');
    return SpendingStatsModel.fromJson(response.data);
  }

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

  Future<List<NotificationModel>> getNotifications(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _dio.get('/api/notifications', queryParameters: {
      'user_id': userId,
      'limit': limit,
      'offset': offset,
    });
    final list = response.data as List;
    return list.map((n) => NotificationModel.fromJson(n)).toList();
  }

  Future<int> getUnreadNotificationCount(String userId) async {
    final response = await _dio.get('/api/notifications/unread-count', queryParameters: {
      'user_id': userId,
    });
    return response.data['unread_count'] as int;
  }

  Future<void> markNotificationRead(String notificationId, String userId) async {
    await _dio.post('/api/notifications/$notificationId/read', data: {
      'user_id': userId,
    });
  }
}
