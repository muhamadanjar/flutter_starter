import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  static final logger = Logger();

  late FirebaseMessaging _messaging;

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  // Initialize Firebase
  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;

      // Request notification permissions (iOS/web)
      await _requestNotificationPermission();

      // Set foreground notification presentation options
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages (when app is terminated)
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      debugPrint('[Firebase] Initialized successfully');
    } catch (e) {
      logger.e('[Firebase] Initialization failed: $e');
      rethrow;
    }
  }

  // Request notification permissions
  Future<void> _requestNotificationPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('[Firebase] Notification permission status: ${settings.authorizationStatus}');
  }

  // Get FCM token
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('[Firebase] FCM Token: $token');
      return token;
    } catch (e) {
      logger.e('[Firebase] Failed to get FCM token: $e');
      return null;
    }
  }

  // Refresh FCM token
  Future<String?> refreshToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('[Firebase] FCM Token refreshed: $token');
      return token;
    } catch (e) {
      logger.e('[Firebase] Failed to refresh FCM token: $e');
      return null;
    }
  }

  // Listen to token refresh
  Stream<String> get onTokenRefresh {
    return _messaging.onTokenRefresh;
  }

  // Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('[Firebase] Foreground message received');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    // You can show a dialog, snackbar, or custom notification here
    // Example: Show a custom notification
  }

  // Handle background/terminated messages
  @pragma('vm:entry-point')
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('[Firebase] Background message received');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    // Handle background message logic
    // Note: Limited execution time in background
  }

  // Handle notification tap
  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    debugPrint('[Firebase] Notification tapped');
    debugPrint('Data: ${message.data}');

    // Navigate to specific screen based on message data
    // Example: If message.data['screen'] == 'dashboard'
    //   Navigator.pushNamed(context, '/dashboard')
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('[Firebase] Subscribed to topic: $topic');
    } catch (e) {
      logger.e('[Firebase] Failed to subscribe to topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('[Firebase] Unsubscribed from topic: $topic');
    } catch (e) {
      logger.e('[Firebase] Failed to unsubscribe from topic: $e');
    }
  }

  // Get initial message (when app is opened from terminated state)
  Future<RemoteMessage?> getInitialMessage() async {
    return _messaging.getInitialMessage();
  }
}
