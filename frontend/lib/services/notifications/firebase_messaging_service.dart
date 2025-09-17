import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../service_locator.dart';

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  String? _fcmToken;
  bool _isInitialized = false;

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  /// Firebase Messaging'i başlatır
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Firebase'i başlat
      await Firebase.initializeApp();
      
      // Local notifications'ı başlat
      await _initializeLocalNotifications();
      
      // FCM token'ı al
      await _getFCMToken();
      
      // Message handlers'ları ayarla
      _setupMessageHandlers();
      
      // Notification permissions'ı kontrol et
      await _requestNotificationPermissions();
      
      _isInitialized = true;
      print('✅ Firebase Messaging başarıyla başlatıldı');
      
    } catch (e) {
      print('❌ Firebase Messaging başlatma hatası: $e');
      throw Exception('Firebase Messaging başlatılamadı: $e');
    }
  }

  /// Local notifications'ı başlatır
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

    // Android için notification channel oluştur
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }
  }

  /// Android notification channel oluşturur
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'motoapp_notifications',
      'MotoApp Bildirimleri',
      description: 'MotoApp uygulaması için bildirimler',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// FCM token'ı alır ve backend'e kaydeder
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      print('📱 FCM Token: $_fcmToken');
      
      if (_fcmToken != null) {
        // Token'ı backend'e kaydet
        await ServiceLocator.notifications.saveFCMToken(_fcmToken!);
      }
    } catch (e) {
      print('❌ FCM Token alınamadı: $e');
    }
  }

  /// Notification permissions'ı ister
  Future<void> _requestNotificationPermissions() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('📱 Notification permissions: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('⚠️ Notification permissions reddedildi');
      }
    } catch (e) {
      print('❌ Notification permissions hatası: $e');
    }
  }

  /// Message handlers'ları ayarlar
  void _setupMessageHandlers() {
    // Foreground mesajları
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Background mesajları
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    
    // App kapalıyken gelen mesajlar
    FirebaseMessaging.onBackgroundMessage(_handleAppTerminatedMessage);
  }

  /// Foreground'da gelen mesajları handle eder
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📨 Foreground message alındı: ${message.messageId}');
    
    // Kullanıcının notification preferences'ını kontrol et
    final preferences = await ServiceLocator.notifications.getNotificationPreferences();
    
    // Eğer push notifications kapalıysa, local notification gösterme
    if (preferences['push_enabled'] == false) {
      print('🔕 Push notifications kapalı, bildirim gösterilmiyor');
      return;
    }

    // Local notification göster
    await _showLocalNotification(message);
  }

  /// Background'da gelen mesajları handle eder
  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('📨 Background message alındı: ${message.messageId}');
    
    // Background'da gelen mesajlar için özel işlem yapılabilir
    // Örneğin: navigation, data update, etc.
  }

  /// App kapalıyken gelen mesajları handle eder
  static Future<void> _handleAppTerminatedMessage(RemoteMessage message) async {
    print('📨 App terminated message alındı: ${message.messageId}');
    
    // App kapalıyken gelen mesajlar için özel işlem yapılabilir
  }

  /// Local notification gösterir
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'motoapp_notifications',
      'MotoApp Bildirimleri',
      channelDescription: 'MotoApp uygulaması için bildirimler',
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
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }

  /// Notification'a tıklandığında çalışır
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification tıklandı: ${response.payload}');
    
    // Notification payload'ından navigation yapılabilir
    // Örneğin: chat sayfasına git, profil sayfasına git, etc.
  }

  /// Token'ı yeniler
  Future<void> refreshToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        await ServiceLocator.notifications.saveFCMToken(_fcmToken!);
        print('🔄 FCM Token yenilendi');
      }
    } catch (e) {
      print('❌ FCM Token yenileme hatası: $e');
    }
  }

  /// Belirli bir konuya subscribe olur
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('📢 Topic\'e subscribe olundu: $topic');
    } catch (e) {
      print('❌ Topic subscribe hatası: $e');
    }
  }

  /// Belirli bir konudan unsubscribe olur
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('📢 Topic\'den unsubscribe olundu: $topic');
    } catch (e) {
      print('❌ Topic unsubscribe hatası: $e');
    }
  }

  /// Servisi temizler
  void dispose() {
    // Firebase Messaging dispose işlemi
    print('🧹 Firebase Messaging Service temizlendi');
  }
}
