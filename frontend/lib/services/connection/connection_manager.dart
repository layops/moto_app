// lib/services/connection/connection_manager.dart
import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';

enum ConnectionType { websocket, sse, polling }
enum NetworkQuality { excellent, good, poor, offline }

class ConnectionManager {
  static final ConnectionManager _instance = ConnectionManager._internal();
  factory ConnectionManager() => _instance;
  ConnectionManager._internal();

  // Stream controllers
  final StreamController<ConnectionType> _connectionTypeController = 
      StreamController<ConnectionType>.broadcast();
  final StreamController<NetworkQuality> _networkQualityController = 
      StreamController<NetworkQuality>.broadcast();
  final StreamController<bool> _isConnectedController = 
      StreamController<bool>.broadcast();
  
  // Stream controller durumu
  bool _isDisposed = false;

  // State
  ConnectionType _currentConnectionType = ConnectionType.websocket;
  NetworkQuality _currentNetworkQuality = NetworkQuality.good;
  bool _isConnected = false;
  int _batteryLevel = 100;
  
  // Timers
  Timer? _healthCheckTimer;
  Timer? _networkCheckTimer;
  Timer? _batteryCheckTimer;
  
  // Services
  final Connectivity _connectivity = Connectivity();
  final Battery _battery = Battery();

  // Getters
  ConnectionType get currentConnectionType => _currentConnectionType;
  NetworkQuality get currentNetworkQuality => _currentNetworkQuality;
  bool get isConnected => _isConnected;
  
  Stream<ConnectionType> get connectionTypeStream => _connectionTypeController.stream;
  Stream<NetworkQuality> get networkQualityStream => _networkQualityController.stream;
  Stream<bool> get isConnectedStream => _isConnectedController.stream;

  /// Connection Manager'ı başlatır
  Future<void> initialize() async {
    print('🚀 Connection Manager başlatılıyor...');
    
    // İlk durumları al
    await _checkBatteryLevel();
    await _checkNetworkQuality();
    
    // Periyodik kontrolleri başlat
    _startHealthChecks();
    
    // Network değişikliklerini dinle
    _connectivity.onConnectivityChanged.listen((result) {
      _checkNetworkQuality();
    });
    
    print('✅ Connection Manager başlatıldı');
  }

  /// En iyi bağlantı türünü belirler
  ConnectionType determineBestConnectionType() {
    // Offline ise polling
    if (_currentNetworkQuality == NetworkQuality.offline) {
      return ConnectionType.polling;
    }
    
    // Pil seviyesi düşükse polling
    if (_batteryLevel < 20) {
      return ConnectionType.polling;
    }
    
    // Ağ kalitesi kötüyse SSE
    if (_currentNetworkQuality == NetworkQuality.poor) {
      return ConnectionType.sse;
    }
    
    // Ağ kalitesi iyiyse WebSocket
    if (_currentNetworkQuality == NetworkQuality.excellent || 
        _currentNetworkQuality == NetworkQuality.good) {
      return ConnectionType.websocket;
    }
    
    // Varsayılan olarak SSE
    return ConnectionType.sse;
  }

  /// Bağlantı türünü günceller
  void updateConnectionType(ConnectionType type) {
    if (_isDisposed) return;
    
    if (_currentConnectionType != type) {
      _currentConnectionType = type;
      if (!_connectionTypeController.isClosed) {
        _connectionTypeController.add(type);
      }
      print('🔄 Bağlantı türü güncellendi: $type');
    }
  }

  /// Bağlantı durumunu günceller
  void updateConnectionStatus(bool connected) {
    if (_isDisposed) return;
    
    if (_isConnected != connected) {
      _isConnected = connected;
      if (!_isConnectedController.isClosed) {
        _isConnectedController.add(connected);
      }
      print('🔗 Bağlantı durumu: ${connected ? "Bağlı" : "Bağlı değil"}');
    }
  }

  /// Ağ kalitesini kontrol eder
  Future<void> _checkNetworkQuality() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      
      if (connectivityResults.contains(ConnectivityResult.none)) {
        _currentNetworkQuality = NetworkQuality.offline;
      } else {
        // Ağ kalitesini test et
        final quality = await _testNetworkQuality();
        _currentNetworkQuality = quality;
      }
      
      if (!_networkQualityController.isClosed) {
        _networkQualityController.add(_currentNetworkQuality);
      }
      print('📶 Ağ kalitesi: $_currentNetworkQuality');
      
      // Ağ kalitesi değiştiyse bağlantı türünü yeniden değerlendir
      final bestType = determineBestConnectionType();
      updateConnectionType(bestType);
      
    } catch (e) {
      print('❌ Ağ kalitesi kontrol hatası: $e');
      _currentNetworkQuality = NetworkQuality.poor;
    }
  }

  /// Ağ kalitesini test eder
  Future<NetworkQuality> _testNetworkQuality() async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Test URL'si (küçük bir dosya)
      final uri = Uri.parse('https://httpbin.org/bytes/1024');
      final client = HttpClient();
      
      final request = await client.getUrl(uri);
      final response = await request.close();
      
      stopwatch.stop();
      client.close();
      
      if (response.statusCode == 200) {
        final responseTime = stopwatch.elapsedMilliseconds;
        
        if (responseTime < 500) {
          return NetworkQuality.excellent;
        } else if (responseTime < 1500) {
          return NetworkQuality.good;
        } else {
          return NetworkQuality.poor;
        }
      } else {
        return NetworkQuality.poor;
      }
    } catch (e) {
      return NetworkQuality.poor;
    }
  }

  /// Pil seviyesini kontrol eder
  Future<void> _checkBatteryLevel() async {
    try {
      _batteryLevel = await _battery.batteryLevel;
      print('🔋 Pil seviyesi: $_batteryLevel%');
      
      // Pil seviyesi değiştiyse bağlantı türünü yeniden değerlendir
      final bestType = determineBestConnectionType();
      updateConnectionType(bestType);
      
    } catch (e) {
      print('❌ Pil seviyesi kontrol hatası: $e');
      _batteryLevel = 100; // Varsayılan değer
    }
  }

  /// Sağlık kontrollerini başlatır
  void _startHealthChecks() {
    // Her 30 saniyede bağlantı durumunu kontrol et
    _healthCheckTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (!_isConnected) {
        print('⚠️ Bağlantı kesildi, yeniden bağlanma stratejisi başlatılıyor...');
        _triggerReconnection();
      }
    });
    
    // Her 60 saniyede ağ kalitesini kontrol et
    _networkCheckTimer = Timer.periodic(Duration(seconds: 60), (timer) {
      _checkNetworkQuality();
    });
    
    // Her 120 saniyede pil seviyesini kontrol et
    _batteryCheckTimer = Timer.periodic(Duration(seconds: 120), (timer) {
      _checkBatteryLevel();
    });
  }

  /// Yeniden bağlanma stratejisini tetikler
  void _triggerReconnection() {
    final bestType = determineBestConnectionType();
    updateConnectionType(bestType);
    
    // Bağlantı türüne göre yeniden bağlanma stratejisi
    switch (bestType) {
      case ConnectionType.websocket:
        print('🔄 WebSocket ile yeniden bağlanma...');
        break;
      case ConnectionType.sse:
        print('🔄 SSE ile yeniden bağlanma...');
        break;
      case ConnectionType.polling:
        print('🔄 Polling ile yeniden bağlanma...');
        break;
    }
  }

  /// Optimize edilmiş polling interval'ı döndürür
  Duration getOptimalPollingInterval() {
    if (_batteryLevel < 20) {
      return Duration(seconds: 120); // Pil azsa daha az sık
    } else if (_currentNetworkQuality == NetworkQuality.poor) {
      return Duration(seconds: 60); // Ağ kötüyse orta sıklık
    } else {
      return Duration(seconds: 30); // Normal sıklık - SSE yerine polling kullanıyoruz
    }
  }

  /// Bağlantı türüne göre timeout süresini döndürür
  Duration getConnectionTimeout() {
    switch (_currentConnectionType) {
      case ConnectionType.websocket:
        return Duration(seconds: 10);
      case ConnectionType.sse:
        return Duration(seconds: 15);
      case ConnectionType.polling:
        return Duration(seconds: 30);
    }
  }

  /// Bağlantı türüne göre retry stratejisini döndürür
  List<int> getRetryDelays() {
    switch (_currentConnectionType) {
      case ConnectionType.websocket:
        return [1, 2, 5, 10, 30]; // Hızlı retry
      case ConnectionType.sse:
        return [2, 5, 10, 20, 60]; // Orta retry
      case ConnectionType.polling:
        return [5, 15, 30, 60, 120]; // Yavaş retry
    }
  }

  /// Connection Manager'ı temizler
  void dispose() {
    if (_isDisposed) return;
    
    _isDisposed = true;
    
    _healthCheckTimer?.cancel();
    _networkCheckTimer?.cancel();
    _batteryCheckTimer?.cancel();
    
    if (!_connectionTypeController.isClosed) {
      _connectionTypeController.close();
    }
    if (!_networkQualityController.isClosed) {
      _networkQualityController.close();
    }
    if (!_isConnectedController.isClosed) {
      _isConnectedController.close();
    }
    
    print('🧹 Connection Manager temizlendi');
  }
}
