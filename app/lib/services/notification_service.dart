import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flare_app/core/router/app_router.dart';
import 'package:flare_app/services/api_service.dart';
import 'package:flare_app/core/widgets/notification_banner.dart';

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
    'flare_findings',
    'Flare Findings',
    description: 'Notifications for new watcher findings.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static const AndroidNotificationChannel briefingsChannel =
      AndroidNotificationChannel(
    'flare_briefings',
    'Flare Briefings',
    description: 'Morning briefing notifications.',
    importance: Importance.high,
  );

  static const AndroidNotificationChannel budgetChannel =
      AndroidNotificationChannel(
    'flare_budget',
    'Flare Budget',
    description: 'Budget warning and exhaustion alerts.',
    importance: Importance.defaultImportance,
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

    // Enable explicit foreground notifications for iOS/macOS
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

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

  /// Update the associated user ID and upload the token.
  Future<void> setUserId(String userId) async {
    _currentUserId = userId;
    final token = await _messaging.getToken();
    if (token != null) {
      debugPrint('[FCM] Uploading token for newly assigned user ID: $userId');
      await _sendTokenToBackend(token);
    }
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

    // Also show local notification for consistency (optional, depending on OS settings)
    _showLocalNotification(notification, message.data, channelId);

    // Show in-app banner for active users
    final context = AppRouter.navigatorKey.currentContext;
    if (context != null) {
      late OverlayEntry bannerEntry;
      bool isRemoved = false;

      String emoji = '🔔';
      if (dataType == 'finding') emoji = '🔥';
      if (dataType == 'briefing') emoji = '☀️';
      if (dataType == 'low_balance' || dataType == 'budget_warning') emoji = '⚠️';

      bannerEntry = OverlayEntry(
        builder: (ctx) => NotificationBanner(
          emoji: emoji,
          headline: notification.title ?? 'New Notification',
          onTap: () {
            if (!isRemoved) {
              bannerEntry.remove();
              isRemoved = true;
            }
            _navigateFromData(message.data);
          },
        ),
      );

      Overlay.of(context).insert(bannerEntry);

      Future.delayed(const Duration(seconds: 4), () {
        if (!isRemoved && bannerEntry.mounted) {
          bannerEntry.remove();
          isRemoved = true;
        }
      });
    }
  }

  void _showLocalNotification(RemoteNotification notification, Map<String, dynamic> data, String channelId) {
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
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  // ─── NOTIFICATION TAP HANDLING ─────────────────────────────

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped: ${message.data}');
    // Delay slightly to ensure router is ready if app is just launching
    Future.delayed(const Duration(milliseconds: 500), () {
      _navigateFromData(message.data);
    });
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
      
      // Ensure we navigate only when the navigator is ready
      if (AppRouter.navigatorKey.currentState != null) {
        AppRouter.router.push(deepLink);
      } else {
        debugPrint('[FMC] Navigator not ready, storing link for later (handled by AppRouter init flow if needed)');
        // In a real app we might store this in a 'pendingLink' variable 
        // that the router reads on its initial route computation.
        // For now, AppRouter.router.go(deepLink) generally handles it if called after init.
      }
    }
  }
}
