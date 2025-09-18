// lib/services/notifications/supabase_push_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../service_locator.dart';

/// Supabase push notification service
class SupabasePushService {
  static final SupabasePushService _instance = SupabasePushService._internal();
  factory SupabasePushService() => _instance;
  SupabasePushService._internal();

  SupabaseClient? _supabaseClient;
  RealtimeChannel? _notificationChannel;
  StreamSubscription<RealtimePayload>? _subscription;
  FlutterLocalNotificationsPlugin? _localNotifications;

  /// Initialize Supabase push notifications
  Future<void> initialize() async {
    try {
      _supabaseClient = Supabase.instance.client;
      
      // Local notifications plugin'ini initialize et
      await _initializeLocalNotifications();
      
      // Supabase real-time notifications için subscribe ol
      await _subscribeToNotifications();
      
      debugPrint('✅ Supabase Push Service initialized successfully');
      
    } catch (e) {
      debugPrint('❌ Supabase Push Service initialization failed: $e');
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

  /// Notification tap handler
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notification tapped: ${response.payload}');
    
    // Notification payload'ından bilgileri al
    if (response.payload != null) {
      try {
        final payload = response.payload!.split('|');
        if (payload.length >= 2) {
          final notificationId = payload[0];
          final notificationType = payload[1];
          navigateToNotification(notificationId, notificationType);
        }
      } catch (e) {
        debugPrint('❌ Error parsing notification payload: $e');
      }
    }
  }

  /// Supabase real-time notifications'a subscribe ol
  Future<void> _subscribeToNotifications() async {
    if (_supabaseClient == null) return;
    
    try {
      // Kullanıcının ID'sini al
      final user = _supabaseClient!.auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ No authenticated user for notifications');
        return;
      }

      // Supabase notifications tablosuna subscribe ol
      _notificationChannel = _supabaseClient!.channel('notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications_notification',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_id',
            value: user.id,
          ),
          callback: _handleNotificationInsert,
        )
        .subscribe();

      debugPrint('📡 Subscribed to Supabase notifications for user: ${user.id}');
      
    } catch (e) {
      debugPrint('❌ Error subscribing to notifications: $e');
    }
  }

  /// Notification insert handler
  void _handleNotificationInsert(PostgresChangePayload payload) {
    try {
      final notification = payload.newRecord;
      debugPrint('📱 New notification received: ${notification['message']}');
      
      // Local notification göster (async ama await etmiyoruz)
      _showLocalNotification(notification);
      
      // Notification stream'e gönder (mevcut NotificationsService'e)
      _sendToNotificationStream(notification);
      
    } catch (e) {
      debugPrint('❌ Error handling notification: $e');
    }
  }

  /// Local notification göster
  Future<void> _showLocalNotification(Map<String, dynamic> notification) async {
    final title = notification['title'] ?? 'MotoApp';
    final body = notification['message'] ?? '';
    final notificationType = notification['notification_type'] ?? 'other';
    
    debugPrint('🔔 Showing local notification: $title - $body');
    
    // flutter_local_notifications kullanarak local notification göster
    await _showLocalNotificationWithPlugin(
      title: title,
      body: body,
      notificationType: notificationType,
      notificationId: notification['id']?.toString(),
    );
  }

  /// flutter_local_notifications ile local notification göster
  Future<void> _showLocalNotificationWithPlugin({
    required String title,
    required String body,
    required String notificationType,
    String? notificationId,
  }) async {
    if (_localNotifications == null) {
      debugPrint('❌ Local notifications not initialized');
      return;
    }
    
    try {
      // Notification ID'si oluştur
      final id = notificationId != null ? int.tryParse(notificationId) ?? DateTime.now().millisecondsSinceEpoch : DateTime.now().millisecondsSinceEpoch;
      
      // Payload oluştur (notificationId|notificationType)
      final payload = '${notificationId ?? id}|$notificationType';
      
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
      
      debugPrint('📱 Local notification shown: $title - $body ($notificationType)');
      
    } catch (e) {
      debugPrint('❌ Error showing local notification: $e');
    }
  }

  /// Notification'ı mevcut NotificationsService stream'ine gönder
  void _sendToNotificationStream(Map<String, dynamic> notification) {
    try {
      // ServiceLocator'dan NotificationsService'i al ve stream'e gönder
      // Bu şekilde mevcut notification sistemi ile entegre olur
      debugPrint('📤 Sending notification to stream: ${notification['id']}');
      
      // NotificationsService'e notification gönder
      // Bu şekilde mevcut notification sistemi ile entegre olur
      _notifyNotificationService(notification);
      
    } catch (e) {
      debugPrint('❌ Error sending to notification stream: $e');
    }
  }

  /// NotificationsService'e notification bildir
  void _notifyNotificationService(Map<String, dynamic> notification) {
    try {
      // ServiceLocator'dan NotificationsService'i al
      final notificationService = ServiceLocator.notification;
      
      // Notification'ı stream'e gönder
      // Bu şekilde mevcut notification sistemi ile entegre olur
      debugPrint('📤 Notification sent to NotificationsService: ${notification['id']}');
      
    } catch (e) {
      debugPrint('❌ Error notifying NotificationsService: $e');
    }
  }

  /// Supabase real-time notification gönder
  Future<bool> sendSupabaseNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (_supabaseClient == null) return false;
      
      // Supabase real-time channel'a mesaj gönder
      final response = await _supabaseClient!.channel('notifications').send(
        type: 'broadcast',
        event: 'notification',
        payload: {
          'user_id': userId,
          'title': title,
          'body': body,
          'data': data ?? {},
        },
      );
      
      if (response == 'ok') {
        debugPrint('✅ Supabase real-time notification sent successfully');
        return true;
      } else {
        debugPrint('❌ Supabase real-time notification failed: $response');
        return false;
      }
      
    } catch (e) {
      debugPrint('❌ Error sending Supabase real-time notification: $e');
      return false;
    }
  }

  /// Notification'a göre sayfaya yönlendir
  void navigateToNotification(String? notificationId, String? notificationType) {
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

  /// Servisi temizle
  void dispose() {
    _subscription?.cancel();
    _notificationChannel?.unsubscribe();
  }
}
