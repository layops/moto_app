// lib/services/notifications/fcm_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../service_locator.dart';
import '../http/api_client.dart';
import '../../firebase_options.dart';

/// Firebase Cloud Messaging Service
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  FirebaseMessaging? _messaging;
  FlutterLocalNotificationsPlugin? _localNotifications;
  String? _fcmToken;

  /// Initialize FCM
  Future<void> initialize() async {
    try {
      // Firebase'i initialize et
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      _messaging = FirebaseMessaging.instance;
      
      // Local notifications plugin'ini initialize et
      await _initializeLocalNotifications();
      
      // FCM token'ı al
      await _getFCMToken();
      
      // Background message handler'ı ayarla
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Foreground message handler'ı ayarla
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Notification tap handler'ı ayarla
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      
      debugPrint('✅ FCM Service initialized successfully');
      
    } catch (e) {
      debugPrint('❌ FCM Service initialization failed: $e');
    }
  }

  /// Local notifications plugin'ini initialize et
  Future<void> _initializeLocalNotifications() async {
    try {
      _localNotifications = FlutterLocalNotificationsPlugin();
      
      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      // Initialization settings
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      // Initialize plugin
      await _localNotifications!.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      debugPrint('✅ Local notifications initialized successfully');
      
    } catch (e) {
      debugPrint('❌ Local notifications initialization failed: $e');
    }
  }

  /// FCM token'ı al ve backend'e gönder
  Future<void> _getFCMToken() async {
    try {
      if (_messaging == null) return;
      
      // Notification permission'ı iste
      await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      // FCM token'ı al
      _fcmToken = await _messaging!.getToken();
      
      if (_fcmToken != null) {
        debugPrint('🔑 FCM Token: $_fcmToken');
        print('🔑 FCM Token (Console): $_fcmToken'); // Console'a da yazdır
        
        // Backend'e FCM token'ı gönder
        await _sendFCMTokenToBackend(_fcmToken!);
      } else {
        debugPrint('❌ FCM Token alınamadı');
        print('❌ FCM Token alınamadı');
      }
      
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
    }
  }

  /// FCM token'ı backend'e gönder
  Future<void> _sendFCMTokenToBackend(String fcmToken) async {
    try {
      final apiClient = ServiceLocator.api;
      
      // Kullanıcı giriş yapmışsa token'ı gönder
      final authService = ServiceLocator.auth;
      if (authService.isAuthenticated) {
        final response = await apiClient.post(
          'notifications/fcm-token/',
          {'fcm_token': fcmToken},
        );
        
        if (response.statusCode == 200) {
          debugPrint('✅ FCM token sent to backend successfully');
        } else {
          debugPrint('❌ Failed to send FCM token to backend: ${response.statusCode}');
        }
      } else {
        debugPrint('ℹ️ FCM token alındı ama kullanıcı giriş yapmamış, token gönderilmedi');
      }
      
    } catch (e) {
      debugPrint('❌ Error sending FCM token to backend: $e');
    }
  }

  /// Foreground message handler
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📱 Foreground message received: ${message.notification?.title}');
    
    // Local notification göster
    _showLocalNotification(
      title: message.notification?.title ?? 'MotoApp',
      body: message.notification?.body ?? '',
      data: message.data,
    );
  }

  /// Notification tap handler
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('📱 Notification tapped: ${message.data}');
    
    // Notification'a göre sayfaya yönlendir
    final notificationType = message.data['notification_type'];
    final notificationId = message.data['notification_id'];
    
    _navigateToNotification(notificationId, notificationType);
  }

  /// Local notification göster
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (_localNotifications == null) return;
    
    try {
      final id = DateTime.now().millisecondsSinceEpoch;
      final payload = data != null ? data.toString() : '';
      
      // Android notification details
      const androidDetails = AndroidNotificationDetails(
        'motoapp_notifications',
        'MotoApp Notifications',
        channelDescription: 'MotoApp push notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );
      
      // iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      // Notification details
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // Notification göster
      await _localNotifications!.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      
      debugPrint('📱 Local notification shown: $title - $body');
      
    } catch (e) {
      debugPrint('❌ Error showing local notification: $e');
    }
  }

  /// Notification tap handler
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Local notification tapped: ${response.payload}');
    
    // Payload'ı parse et ve yönlendir
    if (response.payload != null) {
      try {
        // Payload parsing logic buraya eklenebilir
        _navigateToNotification(null, null);
      } catch (e) {
        debugPrint('❌ Error parsing notification payload: $e');
      }
    }
  }

  /// Notification'a göre sayfaya yönlendir
  void _navigateToNotification(String? notificationId, String? notificationType) {
    if (notificationId == null) return;
    
    // ServiceLocator'dan navigator'ı al
    final navigator = ServiceLocator.navigatorKey.currentState;
    if (navigator == null) return;
    
    // Notification type'a göre yönlendirme
    switch (notificationType) {
      case 'message':
        navigator.pushNamed('/messages');
        break;
      case 'like':
      case 'comment':
        navigator.pushNamed('/home');
        break;
      case 'follow':
        navigator.pushNamed('/home');
        break;
      case 'event_join_request':
      case 'event_join_approved':
      case 'event_join_rejected':
        navigator.pushNamed('/events');
        break;
      case 'group_invite':
      case 'group_join_request':
        navigator.pushNamed('/groups');
        break;
      default:
        navigator.pushNamed('/notifications');
        break;
    }
  }

  /// FCM token'ı al
  String? get fcmToken => _fcmToken;

  /// Login sonrası FCM token'ı backend'e gönder
  Future<void> sendTokenAfterLogin() async {
    if (_fcmToken != null) {
      await _sendFCMTokenToBackend(_fcmToken!);
    }
  }

  /// Servisi temizle
  void dispose() {
    // Cleanup if needed
  }
}

/// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📱 Background message received: ${message.notification?.title}');
  
  // Background'da gelen mesajları işle
  // Bu fonksiyon uygulama kapalıyken çalışır
}
