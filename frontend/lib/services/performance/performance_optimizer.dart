import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'package:flutter/foundation.dart';

/// Performans optimizasyonu için yardımcı sınıf
class PerformanceOptimizer {
  static const int _maxConcurrentOperations = 3;
  static final Semaphore _semaphore = Semaphore(_maxConcurrentOperations);

  /// Ana thread'i bloklamadan ağır işlemleri yapar
  static Future<T> runInBackground<T>(
    Future<T> Function() computation, {
    String? debugLabel,
  }) async {
    if (kDebugMode && debugLabel != null) {
    }

    return await _semaphore.acquire(() async {
      try {
        final result = await computation();
        if (kDebugMode && debugLabel != null) {
        }
        return result;
      } catch (e) {
        if (kDebugMode && debugLabel != null) {
        }
        rethrow;
      }
    });
  }

  /// Batch işlemler için yardımcı
  static Future<List<T>> processBatch<T, R>(
    List<R> items,
    Future<T> Function(R item) processor, {
    int batchSize = 5,
    Duration delayBetweenBatches = const Duration(milliseconds: 10),
  }) async {
    final List<T> results = [];
    
    for (int i = 0; i < items.length; i += batchSize) {
      final batch = items.skip(i).take(batchSize);
      
      final batchResults = await Future.wait(
        batch.map(processor),
      );
      
      results.addAll(batchResults);
      
      // Ana thread'i bloklamamak için kısa bekleme
      if (i + batchSize < items.length) {
        await Future.delayed(delayBetweenBatches);
      }
    }
    
    return results;
  }

  /// Debounce işlemleri için yardımcı
  static Timer? _debounceTimer;
  
  static void debounce(
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }

  /// Throttle işlemleri için yardımcı
  static DateTime? _lastExecution;
  
  static bool throttle({
    Duration interval = const Duration(milliseconds: 500),
  }) {
    final now = DateTime.now();
    if (_lastExecution == null || 
        now.difference(_lastExecution!) > interval) {
      _lastExecution = now;
      return true;
    }
    return false;
  }
}

/// Semaphore sınıfı - eşzamanlı işlem sayısını sınırlar
class Semaphore {
  final int _maxCount;
  int _currentCount;
  final Queue<Completer<void>> _waitingQueue = Queue<Completer<void>>();

  Semaphore(this._maxCount) : _currentCount = _maxCount;

  Future<T> acquire<T>(Future<T> Function() computation) async {
    await _acquire();
    try {
      return await computation();
    } finally {
      _release();
    }
  }

  Future<void> _acquire() async {
    if (_currentCount > 0) {
      _currentCount--;
      return;
    }

    final completer = Completer<void>();
    _waitingQueue.add(completer);
    return completer.future;
  }

  void _release() {
    if (_waitingQueue.isNotEmpty) {
      final completer = _waitingQueue.removeFirst();
      completer.complete();
    } else {
      _currentCount++;
    }
  }
}
