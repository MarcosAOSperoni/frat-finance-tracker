import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:frat_finance_tracker/shared/services/supabase_service.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Request notification permissions and get FCM token
  static Future<void> initialize() async {
    try {
      print('🔔 Starting FCM initialization...');

      // Initialize local notifications
      await _initializeLocalNotifications();
      print('🔔 Local notifications initialized');

      // Request permission
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      print('🔔 Notification permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('✅ User granted permission for notifications');

        // Get FCM token
        final token = await _firebaseMessaging.getToken();
        if (token != null) {
          print('✅ FCM Token: $token');
          await _saveFCMToken(token);
        }

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen(_saveFCMToken);

        // Handle foreground messages
        print('🔔 Setting up foreground message listener...');
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          print('🎯 FOREGROUND MESSAGE RECEIVED!');
          print('   Title: ${message.notification?.title}');
          print('   Body: ${message.notification?.body}');
          print('   Data: ${message.data}');
          _handleForegroundMessage(message);
        });
        print('🔔 Foreground message listener set up!');

      } else {
        print('❌ User declined or has not accepted permission');
      }
    } catch (e) {
      print('❌ Error initializing FCM: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  /// Initialize local notifications plugin
  static Future<void> _initializeLocalNotifications() async {
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false, // Already requested via FCM
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettings = InitializationSettings(
      iOS: initializationSettingsIOS,
      android: initializationSettingsAndroid,
    );

    await _localNotifications.initialize(initializationSettings);

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        'frat_finance_channel',
        'Frat Finance Notifications',
        description: 'Notifications for dues and payments',
        importance: Importance.max,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }
  }

  /// Handle messages received when app is in foreground
  static void _handleForegroundMessage(RemoteMessage message) {
    print('📬 Foreground notification received: ${message.notification?.title}');

    final notification = message.notification;
    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? 'New Notification',
        body: notification.body ?? '',
      );
    }
  }

  /// Show a local notification
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const notificationDetails = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      android: AndroidNotificationDetails(
        'frat_finance_channel',
        'Frat Finance Notifications',
        channelDescription: 'Notifications for dues and payments',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      ),
    );

    await _localNotifications.show(
      0, // notification id
      title,
      body,
      notificationDetails,
    );
  }

  /// Save FCM token to Supabase
  static Future<void> _saveFCMToken(String token) async {
    try {
      final client = SupabaseService.client;
      final session = client.auth.currentSession;

      if (session == null) {
        print('No valid session, cannot save FCM token');
        return;
      }

      final userId = session.user.id;

      // Insert or update FCM token
      await client.from('fcm_tokens').upsert({
        'user_id': userId,
        'token': token,
        'device_type': Platform.isAndroid ? 'android' : 'ios',
        'updated_at': DateTime.now().toIso8601String(),
      });

      print('FCM token saved successfully');
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  /// Delete FCM token on logout
  static Future<void> deleteFCMToken() async {
    try {
      final client = SupabaseService.client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) return;

      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await client
            .from('fcm_tokens')
            .delete()
            .eq('user_id', userId)
            .eq('token', token);

        print('FCM token deleted successfully');
      }
    } catch (e) {
      print('Error deleting FCM token: $e');
    }
  }
}
