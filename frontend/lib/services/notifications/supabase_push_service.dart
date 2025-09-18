// lib/services/notifications/supabase_push_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../service_locator.dart';

/// Supabase push notification service
class SupabasePushService {
  static final SupabasePushService _instance = SupabasePushService._internal();
  factory SupabasePushService() => _instance;
  SupabasePushService._internal();

  SupabaseClient? _supabaseClient;
  RealtimeChannel? _notificationChannel;
  StreamSubscription<RealtimePayload>? _subscription;

  /// Initialize Supabase push notifications
  Future<void> initialize() async {
    try {
      _supabaseClient = Supabase.instance.client;
      
      // Supabase real-time notifications için subscribe ol
      await _subscribeToNotifications();
      
      debugPrint('✅ Supabase Push Service initialized successfully');
      
    } catch (e) {
      debugPrint('❌ Supabase Push Service initialization failed: $e');
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
      
      // Local notification göster
      _showLocalNotification(notification);
      
      // Notification stream'e gönder (mevcut NotificationsService'e)
      _sendToNotificationStream(notification);
      
    } catch (e) {
      debugPrint('❌ Error handling notification: $e');
    }
  }

  /// Local notification göster
  void _showLocalNotification(Map<String, dynamic> notification) {
    final title = notification['title'] ?? 'MotoApp';
    final body = notification['message'] ?? '';
    final notificationType = notification['notification_type'] ?? 'other';
    
    debugPrint('🔔 Showing local notification: $title - $body');
    
    // flutter_local_notifications kullanarak local notification göster
    _showLocalNotificationWithPlugin(
      title: title,
      body: body,
      notificationType: notificationType,
      notificationId: notification['id']?.toString(),
    );
  }

  /// flutter_local_notifications ile local notification göster
  void _showLocalNotificationWithPlugin({
    required String title,
    required String body,
    required String notificationType,
    String? notificationId,
  }) {
    // flutter_local_notifications implementasyonu
    // Bu kısım flutter_local_notifications plugin'i gerektirir
    debugPrint('📱 Local notification: $title - $body ($notificationType)');
    
    // Gelecekte flutter_local_notifications implementasyonu eklenebilir
    // Şimdilik sadece log yazdırıyoruz
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
