import 'package:flutter/material.dart';
import 'storage/local_storage.dart';
import 'http/api_client.dart';
import 'auth/auth_service.dart';
import 'auth/token_service.dart';
import 'user/user_service.dart';
import 'user/profile_service.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();

  // Global keys
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // Services
  late final LocalStorage _localStorage;
  late final ApiClient _apiClient;
  late final TokenService _tokenService;
  late final AuthService _authService;
  late final UserService _userService;
  late final ProfileService _profileService;

  // Private constructor
  ServiceLocator._internal();

  // Factory constructor
  factory ServiceLocator() {
    if (!_isInitialized) {
      throw StateError(
          'ServiceLocator has not been initialized. Call ServiceLocator.init() first.');
    }
    return _instance;
  }

  // Initialization status
  static bool _isInitialized = false;

  /// Initialize all services
  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize storage
      _instance._localStorage = LocalStorage();
      await _instance._localStorage.init();

      // 2. Initialize API client
      _instance._apiClient = ApiClient(_instance._localStorage);

      // 3. Initialize token service
      _instance._tokenService = TokenService(_instance._localStorage);

      // 4. Initialize auth service
      _instance._authService = AuthService(
        _instance._apiClient,
        _instance._tokenService,
        _instance._localStorage,
      );

      // 5. Initialize user service
      _instance._userService = UserService(
        _instance._apiClient,
        _instance._localStorage,
      );

      // 6. Initialize profile service
      _instance._profileService = ProfileService(
        _instance._apiClient,
        _instance._tokenService,
      );

      _isInitialized = true;
    } catch (e, stackTrace) {
      await reset(); // _reset yerine reset kullanıyoruz
      throw ServiceLocatorError(
          'ServiceLocator initialization failed', e, stackTrace);
    }
  }

  /// Reset all services (for testing/logout purposes)
  static Future<void> reset() async {
    try {
      await _instance._localStorage.clearAuthData();
      _isInitialized = false;
    } catch (e, stackTrace) {
      throw ServiceLocatorError('Failed to reset services', e, stackTrace);
    }
  }

  // Service getters
  static ApiClient get api => _instance._apiClient;
  static AuthService get auth => _instance._authService;
  static TokenService get token => _instance._tokenService;
  static UserService get user => _instance._userService;
  static ProfileService get profile => _instance._profileService;
  static LocalStorage get storage => _instance._localStorage;

  // Navigation helpers
  static NavigatorState get navigator => navigatorKey.currentState!;
  static ScaffoldMessengerState get messenger =>
      scaffoldMessengerKey.currentState!;
}

/// Custom error class for ServiceLocator
class ServiceLocatorError implements Exception {
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  ServiceLocatorError(this.message, [this.error, this.stackTrace]);

  @override
  String toString() => 'ServiceLocatorError: $message'
      '${error != null ? '\nError: $error' : ''}'
      '${stackTrace != null ? '\nStackTrace: $stackTrace' : ''}';
}
