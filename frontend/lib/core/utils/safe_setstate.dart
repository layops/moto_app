import 'package:flutter/material.dart';

/// Güvenli setState çağrıları için yardımcı sınıf
class SafeSetState {
  /// Widget mounted kontrolü ile güvenli setState çağrısı
  static void call(State state, VoidCallback fn) {
    if (state.mounted) {
      state.setState(fn);
    }
  }

  /// Async işlemlerden sonra güvenli setState çağrısı
  static void callAfterAsync(State state, VoidCallback fn) {
    if (state.mounted) {
      state.setState(fn);
    }
  }

  /// Future işlemlerinden sonra güvenli setState çağrısı
  static Future<T?> safeAsync<T>(
    State state,
    Future<T> Function() asyncOperation,
    void Function(T result)? onSuccess,
    void Function(dynamic error)? onError,
  ) async {
    try {
      final result = await asyncOperation();
      if (state.mounted) {
        onSuccess?.call(result);
      }
      return result;
    } catch (error) {
      if (state.mounted) {
        onError?.call(error);
      }
      return null;
    }
  }
}

/// StatefulWidget'lar için mixin
mixin SafeStateMixin<T extends StatefulWidget> on State<T> {
  /// Güvenli setState çağrısı
  void safeSetState(VoidCallback fn) {
    SafeSetState.call(this, fn);
  }

  /// Async işlemlerden sonra güvenli setState
  void safeSetStateAfterAsync(VoidCallback fn) {
    SafeSetState.callAfterAsync(this, fn);
  }

  /// Güvenli async işlem
  Future<R?> safeAsync<R>(
    Future<R> Function() asyncOperation, {
    void Function(R result)? onSuccess,
    void Function(dynamic error)? onError,
  }) {
    return SafeSetState.safeAsync(
      this,
      asyncOperation,
      onSuccess,
      onError,
    );
  }
}
