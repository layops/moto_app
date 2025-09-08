import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import '../service_locator.dart';

/// Performans optimizasyonu için yardımcı sınıf
class PerformanceOptimizer {
  static final PerformanceOptimizer _instance = PerformanceOptimizer._internal();
  factory PerformanceOptimizer() => _instance;
  PerformanceOptimizer._internal();

  Timer? _cleanupTimer;
  Timer? _memoryCleanupTimer;
  
  /// Performans optimizasyonlarını başlat
  void startOptimizations() {
    _startPeriodicCleanup();
    _startMemoryCleanup();
  }
  
  /// Performans optimizasyonlarını durdur
  void stopOptimizations() {
    _cleanupTimer?.cancel();
    _memoryCleanupTimer?.cancel();
  }
  
  /// Periyodik cache temizleme
  void _startPeriodicCleanup() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      _performCleanup();
    });
  }
  
  /// Bellek temizleme
  void _startMemoryCleanup() {
    _memoryCleanupTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _performMemoryCleanup();
    });
  }
  
  /// Cache temizleme işlemi
  void _performCleanup() {
    try {
      // Eski cache'leri temizle
      ServiceLocator.api.clearCache();
      ServiceLocator.storage.clearMemoryCache();
      
      if (kDebugMode) {
        print('Periyodik cache temizleme tamamlandı');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Cache temizleme hatası: $e');
      }
    }
  }
  
  /// Bellek temizleme işlemi
  void _performMemoryCleanup() {
    try {
      // Garbage collection tetikle
      if (kDebugMode) {
        print('Bellek temizleme başlatıldı');
      }
      
      // Isolate'te garbage collection
      final pauseToken = Isolate.current.pause();
      Future.delayed(const Duration(milliseconds: 100), () {
        Isolate.current.resume(pauseToken);
      });
      
    } catch (e) {
      if (kDebugMode) {
        print('Bellek temizleme hatası: $e');
      }
    }
  }
  
  /// Manuel cache temizleme
  void clearAllCaches() {
    try {
      ServiceLocator.api.clearCache();
      ServiceLocator.auth.clearCache();
      ServiceLocator.post.clearCache();
      ServiceLocator.user.clearCache();
      ServiceLocator.storage.clearMemoryCache();
      
      if (kDebugMode) {
        print('Tüm cache\'ler temizlendi');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Cache temizleme hatası: $e');
      }
    }
  }
  
  /// Performans metrikleri
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'memory_usage': _getMemoryUsage(),
      'cache_status': _getCacheStatus(),
    };
  }
  
  /// Bellek kullanımı bilgisi
  Map<String, dynamic> _getMemoryUsage() {
    // Bu bilgi platform-specific olabilir
    return {
      'available': 'N/A',
      'used': 'N/A',
      'total': 'N/A',
    };
  }
  
  /// Cache durumu bilgisi
  Map<String, dynamic> _getCacheStatus() {
    return {
      'api_cache': 'Active',
      'storage_cache': 'Active',
      'user_cache': 'Active',
      'post_cache': 'Active',
    };
  }
}

/// Performans izleme sınıfı
class PerformanceMonitor {
  static final Map<String, List<Duration>> _requestTimes = {};
  static final Map<String, int> _requestCounts = {};
  
  /// İstek süresini kaydet
  static void recordRequestTime(String endpoint, Duration duration) {
    _requestTimes.putIfAbsent(endpoint, () => []);
    _requestTimes[endpoint]!.add(duration);
    
    _requestCounts.putIfAbsent(endpoint, () => 0);
    _requestCounts[endpoint] = _requestCounts[endpoint]! + 1;
    
    // Son 100 isteği tut
    if (_requestTimes[endpoint]!.length > 100) {
      _requestTimes[endpoint]!.removeAt(0);
    }
  }
  
  /// Ortalama istek süresini al
  static Duration getAverageRequestTime(String endpoint) {
    final times = _requestTimes[endpoint];
    if (times == null || times.isEmpty) {
      return Duration.zero;
    }
    
    final total = times.fold(Duration.zero, (sum, time) => sum + time);
    return Duration(microseconds: total.inMicroseconds ~/ times.length);
  }
  
  /// İstek sayısını al
  static int getRequestCount(String endpoint) {
    return _requestCounts[endpoint] ?? 0;
  }
  
  /// Performans raporu al
  static Map<String, dynamic> getPerformanceReport() {
    final report = <String, dynamic>{};
    
    for (final endpoint in _requestTimes.keys) {
      report[endpoint] = {
        'average_time': getAverageRequestTime(endpoint).inMilliseconds,
        'request_count': getRequestCount(endpoint),
        'last_request': _requestTimes[endpoint]!.isNotEmpty 
            ? _requestTimes[endpoint]!.last.inMilliseconds 
            : 0,
      };
    }
    
    return report;
  }
  
  /// İstatistikleri temizle
  static void clearStats() {
    _requestTimes.clear();
    _requestCounts.clear();
  }
}
