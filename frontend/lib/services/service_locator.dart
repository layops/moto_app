import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart' as supabase_client; // Değişiklik burada
import 'storage/local_storage.dart';
import 'http/api_client.dart';
import 'auth/auth_service.dart';
import 'auth/token_service.dart';
import 'user/user_service.dart';
import 'user/profile_service.dart';
import 'follow/follow_service.dart';
import 'post/post_service.dart';
import 'notifications/notifications_service.dart';

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
  late final FollowService _followService;
  late final PostService _postService;
  late final NotificationsService _notificationService;
  late final supabase_client.SupabaseClient _supabaseClient; // Yeni ekleme

  // Private constructor
  ServiceLocator._internal();

  // Factory constructor
  factory ServiceLocator() {
    if (!_isInitialized) {
      throw StateError(
        'ServiceLocator has not been initialized. Call ServiceLocator.init() first.',
      );
    }
    return _instance;
  }

  // Initialization status
  static bool _isInitialized = false;

  /// Initialize all services
  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      final instance = _instance;

      // 0. Initialize Supabase - Manuel olarak
      instance._supabaseClient = supabase_client.SupabaseClient(
        'https://mosiqkyyribzlvdvedet.supabase.co',
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vc2lxa3l5cmliemx2ZHZlZGV0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY2NDM0NzUsImV4cCI6MjA3MjIxOTQ3NX0.x3_gZOXMbxNd_KAj_UxRif04hwpZ46aARB_ocZZIIbM',
      );

      // 1. Initialize local storage (app)
      instance._localStorage = LocalStorage();
      await instance._localStorage.init();

      // 2. Initialize API client with Dio
      instance._apiClient = ApiClient(instance._localStorage);

      // 3. Initialize token service
      instance._tokenService = TokenService(instance._localStorage);

      // 4. Initialize auth service
      instance._authService = AuthService(
        instance._apiClient,
        instance._tokenService,
        instance._localStorage,
      );

      // 5. Initialize user service
      instance._userService = UserService(
        instance._apiClient,
        instance._localStorage,
      );

      // 6. Initialize profile service
      instance._profileService = ProfileService(
        instance._apiClient,
        instance._tokenService,
      );

      // 7. Initialize follow service
      instance._followService = FollowService(
        instance._apiClient,
        instance._tokenService,
      );

      // 8. Initialize post service
      instance._postService = PostService();

      // 9. Initialize notification service
      instance._notificationService = NotificationsService();

      _isInitialized = true;
    } catch (e, stackTrace) {
      _isInitialized = false;
      throw ServiceLocatorError(
        'ServiceLocator initialization failed',
        e,
        stackTrace,
      );
    }
  }

  /// Reset all services
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
  static FollowService get follow => _instance._followService;
  static PostService get post => _instance._postService;
  static NotificationsService get notification =>
      _instance._notificationService;
  static LocalStorage get storage => _instance._localStorage;

  // Supabase helper - Güncellenmiş
  static supabase_client.SupabaseClient get supabaseClient =>
      _instance._supabaseClient;

  static String? get currentUserId => supabaseClient.auth.currentUser?.id;
  static String? get currentUserEmail => supabaseClient.auth.currentUser?.email;

  // Navigation helpers
  static NavigatorState get navigator => navigatorKey.currentState!;
  static ScaffoldMessengerState get messenger =>
      scaffoldMessengerKey.currentState!;
}

// Custom error class
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
