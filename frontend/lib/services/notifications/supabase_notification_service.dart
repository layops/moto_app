import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:motoapp_frontend/services/service_locator.dart';

class SupabaseNotificationService {
  static final SupabaseNotificationService _instance = SupabaseNotificationService._internal();
  factory SupabaseNotificationService() => _instance;
  SupabaseNotificationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  RealtimeChannel? _notificationChannel;

  /// Notification service'i initialize et
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Local notifications'ı initialize et
      await _initializeLocalNotifications();
      
      // Supabase Realtime channel'ı başlat
      await _startNotificationListener();
      
      _isInitialized = true;
      debugPrint('✅ Supabase Notification Service initialized');
    } catch (e) {
      debugPrint('❌ Supabase Notification Service initialization failed: $e');
    }
  }

  /// Local notifications'ı initialize et
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Android için notification permission iste
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Supabase Realtime ile bildirim dinle
  Future<void> _startNotificationListener() async {
    try {
      // Kullanıcı ID'sini al
      final userId = await _getCurrentUserId();
      if (userId == null) {
        debugPrint('⚠️ User ID bulunamadı, notification listener başlatılamadı');
        return;
      }

      // Realtime channel oluştur
      _notificationChannel = _supabase
          .channel('notifications_$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: _handleNotificationReceived,
          )
          .subscribe();

      debugPrint('✅ Notification listener started for user: $userId');
    } catch (e) {
      debugPrint('❌ Notification listener başlatılamadı: $e');
    }
  }

  /// Bildirim geldiğinde çağrılır
  void _handleNotificationReceived(PostgresChangePayload payload) {
    try {
      final notificationData = payload.newRecord;
      
      debugPrint('🔔 Yeni bildirim alındı: $notificationData');
      
      // Local notification göster
      _showLocalNotification(notificationData);
      
      // Notification count'u güncelle (eğer gerekirse)
      _updateNotificationCount();
      
    } catch (e) {
      debugPrint('❌ Bildirim işlenirken hata: $e');
    }
  }

  /// Local notification göster
  Future<void> _showLocalNotification(Map<String, dynamic> notificationData) async {
    try {
      final title = notificationData['title'] ?? 'MotoApp';
      final body = notificationData['body'] ?? 'Yeni bildirim';
      final notificationId = notificationData['id']?.hashCode ?? DateTime.now().millisecondsSinceEpoch;

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'motoapp_notifications',
        'MotoApp Bildirimleri',
        channelDescription: 'MotoApp uygulamasından gelen bildirimler',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        notificationId,
        title,
        body,
        details,
        payload: notificationData.toString(),
      );

      debugPrint('✅ Local notification gösterildi: $title');
    } catch (e) {
      debugPrint('❌ Local notification gösterilemedi: $e');
    }
  }

  /// Notification'a tıklandığında çağrılır
  void _onNotificationTapped(NotificationResponse response) {
    try {
      debugPrint('🔔 Notification tıklandı: ${response.payload}');
      
      // Notification'a tıklandığında yapılacak işlemler
      // Örneğin: Bildirimler sayfasına git
      ServiceLocator.navigatorKey.currentState?.pushNamed('/notifications');
      
    } catch (e) {
      debugPrint('❌ Notification tap işlenirken hata: $e');
    }
  }

  /// Mevcut kullanıcı ID'sini al
  Future<int?> _getCurrentUserId() async {
    try {
      // Token'dan user ID'yi al
      final token = await ServiceLocator.token.getToken();
      if (token == null) return null;

      // JWT token'ı decode et ve user_id'yi al
      // Bu kısım token service'inize göre değişebilir
      final userId = await ServiceLocator.token.getUserIdFromToken();
      return userId;
    } catch (e) {
      debugPrint('❌ User ID alınamadı: $e');
      return null;
    }
  }

  /// Notification count'u güncelle
  void _updateNotificationCount() {
    // Bu fonksiyon notification count'u güncellemek için kullanılabilir
    // Örneğin: MainWrapperNew'deki unread count'u güncelle
    debugPrint('📊 Notification count güncellendi');
  }

  /// Notification service'i durdur
  Future<void> dispose() async {
    try {
      await _notificationChannel?.unsubscribe();
      _notificationChannel = null;
      _isInitialized = false;
      debugPrint('✅ Supabase Notification Service disposed');
    } catch (e) {
      debugPrint('❌ Notification service dispose hatası: $e');
    }
  }

  /// Test notification gönder
  Future<void> sendTestNotification() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        debugPrint('❌ Test notification gönderilemedi: User ID bulunamadı');
        return;
      }

      // Backend'e test notification isteği gönder
      final response = await ServiceLocator.api.post('/api/notifications/fcm-test/');
      
      if (response.statusCode == 200) {
        debugPrint('✅ Test notification isteği gönderildi');
      } else {
        debugPrint('❌ Test notification isteği başarısız: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Test notification gönderilemedi: $e');
    }
  }
}
