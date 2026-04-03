import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ghost_app/core/router/app_router.dart';
import 'package:ghost_app/services/api_service.dart';

/// Top-level handler for background messages (must be a top-level function).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message received: ${message.messageId}');
}

/// Service responsible for Firebase Cloud Messaging integration.
/// Handles permissions, token management, foreground/background notifications,
/// and deep link navigation from notification taps.
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final ApiService _apiService;
  String? _currentUserId;

  NotificationService(this._apiService);

  // ─── NOTIFICATION CHANNELS ─────────────────────────────────

  static const AndroidNotificationChannel findingsChannel =
      AndroidNotificationChannel(
    'findings_channel',
    'Findings',
    description: 'Notifications for new watcher findings.',
    importance: Importance.high,
  );

  static const AndroidNotificationChannel briefingsChannel =
      AndroidNotificationChannel(
    'briefings_channel',
    'Briefings',
    description: 'Morning briefing notifications.',
    importance: Importance.defaultImportance,
  );

  static const AndroidNotificationChannel budgetChannel =
      AndroidNotificationChannel(
    'budget_channel',
    'Budget Alerts',
    description: 'Budget warning and exhaustion alerts.',
    importance: Importance.low,
  );

  // ─── INITIALIZATION ────────────────────────────────────────

  /// Initialize FCM, request permissions, register token, and set up listeners.
  Future<void> init({String? userId}) async {
    _currentUserId = userId;

    // Register the background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permissions (iOS + Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

    // Create Android notification channels
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(findingsChannel);
      await androidPlugin.createNotificationChannel(briefingsChannel);
      await androidPlugin.createNotificationChannel(budgetChannel);
    }

    // Initialize flutter_local_notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Get and send the current FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      debugPrint('[FCM] Token acquired: ${token.substring(0, 20)}...');
      await _sendTokenToBackend(token);
    }

    // Listen for token refreshes
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('[FCM] Token refreshed.');
      _sendTokenToBackend(newToken);
    });

    // Foreground message handler — show a local notification
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Notification tap handler (app was in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if the app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// Update the associated user ID (e.g., after registration).
  void setUserId(String userId) {
    _currentUserId = userId;
  }

  // ─── TOKEN MANAGEMENT ──────────────────────────────────────

  Future<void> _sendTokenToBackend(String token) async {
    if (_currentUserId == null) {
      debugPrint('[FCM] No userId set. Skipping token upload.');
      return;
    }
    try {
      await _apiService.updateFcmToken(_currentUserId!, token);
      debugPrint('[FCM] Token sent to backend for user $_currentUserId');
    } catch (e) {
      debugPrint('[FCM] Failed to send token to backend: $e');
    }
  }

  // ─── FOREGROUND NOTIFICATIONS ──────────────────────────────

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground message: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    // Determine which channel to use based on the data type
    String channelId = findingsChannel.id;
    final dataType = message.data['type'] as String?;
    if (dataType == 'briefing') {
      channelId = briefingsChannel.id;
    } else if (dataType == 'budget_warning' ||
        dataType == 'budget_exhausted' ||
        dataType == 'low_balance') {
      channelId = budgetChannel.id;
    }

    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId == findingsChannel.id
              ? findingsChannel.name
              : channelId == briefingsChannel.id
                  ? briefingsChannel.name
                  : budgetChannel.name,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  // ─── NOTIFICATION TAP HANDLING ─────────────────────────────

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped: ${message.data}');
    _navigateFromData(message.data);
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _navigateFromData(data);
    } catch (e) {
      debugPrint('[FCM] Failed to parse notification payload: $e');
    }
  }

  /// Extract the deep_link from notification data and navigate using GoRouter.
  void _navigateFromData(Map<String, dynamic> data) {
    final deepLink = data['deep_link'] as String?;
    if (deepLink != null && deepLink.isNotEmpty) {
      debugPrint('[FCM] Navigating to deep link: $deepLink');
      AppRouter.router.go(deepLink);
    }
  }
}
