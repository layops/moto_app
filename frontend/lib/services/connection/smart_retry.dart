// lib/services/connection/smart_retry.dart
import 'dart:async';
import 'dart:math';
import 'connection_manager.dart';

class SmartRetry {
  final ConnectionManager _connectionManager;
  final List<int> _retryDelays;
  int _currentAttempt = 0;
  Timer? _retryTimer;
  bool _isRetrying = false;

  SmartRetry(this._connectionManager) 
      : _retryDelays = _connectionManager.getRetryDelays();

  /// Akıllı yeniden deneme başlatır
  Future<void> startRetry(Future<void> Function() retryFunction) async {
    if (_isRetrying) return;
    
    _isRetrying = true;
    _currentAttempt = 0;
    
    print('🔄 Akıllı retry başlatılıyor...');
    await _executeRetry(retryFunction);
  }

  /// Retry işlemini gerçekleştirir
  Future<void> _executeRetry(Future<void> Function() retryFunction) async {
    if (_currentAttempt >= _retryDelays.length) {
      print('❌ Maksimum retry denemesi aşıldı');
      _isRetrying = false;
      return;
    }

    final delay = _retryDelays[_currentAttempt];
    final jitter = Random().nextInt(1000); // 0-1 saniye rastgele gecikme
    
    print('⏳ ${delay + jitter}ms sonra ${_currentAttempt + 1}. deneme...');
    
    _retryTimer = Timer(Duration(milliseconds: delay + jitter), () async {
      try {
        await retryFunction();
        print('✅ Retry başarılı!');
        _isRetrying = false;
        _currentAttempt = 0;
      } catch (e) {
        print('❌ Retry ${_currentAttempt + 1} başarısız: $e');
        _currentAttempt++;
        
        // Bağlantı türünü yeniden değerlendir
        final bestType = _connectionManager.determineBestConnectionType();
        _connectionManager.updateConnectionType(bestType);
        
        // Sonraki denemeyi başlat
        await _executeRetry(retryFunction);
      }
    });
  }

  /// Retry'ı durdurur
  void stopRetry() {
    _retryTimer?.cancel();
    _isRetrying = false;
    _currentAttempt = 0;
    print('🛑 Retry durduruldu');
  }

  /// Exponential backoff ile retry
  Future<void> startExponentialBackoff(
    Future<void> Function() retryFunction,
    {int maxAttempts = 5, int baseDelay = 1000}
  ) async {
    if (_isRetrying) return;
    
    _isRetrying = true;
    _currentAttempt = 0;
    
    print('🔄 Exponential backoff retry başlatılıyor...');
    await _executeExponentialBackoff(retryFunction, maxAttempts, baseDelay);
  }

  /// Exponential backoff işlemini gerçekleştirir
  Future<void> _executeExponentialBackoff(
    Future<void> Function() retryFunction,
    int maxAttempts,
    int baseDelay
  ) async {
    if (_currentAttempt >= maxAttempts) {
      print('❌ Exponential backoff maksimum deneme aşıldı');
      _isRetrying = false;
      return;
    }

    final delay = baseDelay * pow(2, _currentAttempt).toInt();
    final jitter = Random().nextInt(1000);
    
    print('⏳ ${delay + jitter}ms sonra ${_currentAttempt + 1}. deneme...');
    
    _retryTimer = Timer(Duration(milliseconds: delay + jitter), () async {
      try {
        await retryFunction();
        print('✅ Exponential backoff retry başarılı!');
        _isRetrying = false;
        _currentAttempt = 0;
      } catch (e) {
        print('❌ Exponential backoff retry ${_currentAttempt + 1} başarısız: $e');
        _currentAttempt++;
        
        // Bağlantı türünü yeniden değerlendir
        final bestType = _connectionManager.determineBestConnectionType();
        _connectionManager.updateConnectionType(bestType);
        
        // Sonraki denemeyi başlat
        await _executeExponentialBackoff(retryFunction, maxAttempts, baseDelay);
      }
    });
  }

  /// Circuit breaker pattern ile retry
  Future<void> startCircuitBreaker(
    Future<void> Function() retryFunction,
    {int failureThreshold = 5, Duration timeout = const Duration(minutes: 1)}
  ) async {
    if (_isRetrying) return;
    
    _isRetrying = true;
    _currentAttempt = 0;
    
    print('🔄 Circuit breaker retry başlatılıyor...');
    await _executeCircuitBreaker(retryFunction, failureThreshold, timeout);
  }

  /// Circuit breaker işlemini gerçekleştirir
  Future<void> _executeCircuitBreaker(
    Future<void> Function() retryFunction,
    int failureThreshold,
    Duration timeout
  ) async {
    if (_currentAttempt >= failureThreshold) {
      print('❌ Circuit breaker açık - timeout bekleniyor: ${timeout.inSeconds}s');
      
      _retryTimer = Timer(timeout, () {
        _currentAttempt = 0;
        print('🔄 Circuit breaker kapatıldı, yeniden deneme...');
        _executeCircuitBreaker(retryFunction, failureThreshold, timeout);
      });
      return;
    }

    final delay = _retryDelays[_currentAttempt];
    print('⏳ ${delay}ms sonra ${_currentAttempt + 1}. deneme...');
    
    _retryTimer = Timer(Duration(milliseconds: delay), () async {
      try {
        await retryFunction();
        print('✅ Circuit breaker retry başarılı!');
        _isRetrying = false;
        _currentAttempt = 0;
      } catch (e) {
        print('❌ Circuit breaker retry ${_currentAttempt + 1} başarısız: $e');
        _currentAttempt++;
        
        // Bağlantı türünü yeniden değerlendir
        final bestType = _connectionManager.determineBestConnectionType();
        _connectionManager.updateConnectionType(bestType);
        
        // Sonraki denemeyi başlat
        await _executeCircuitBreaker(retryFunction, failureThreshold, timeout);
      }
    });
  }

  /// Retry durumunu kontrol eder
  bool get isRetrying => _isRetrying;
  int get currentAttempt => _currentAttempt;
  int get maxAttempts => _retryDelays.length;
}
