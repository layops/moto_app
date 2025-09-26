import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart' as supabase_client;
import 'storage/local_storage.dart';
import 'http/api_client.dart';
import 'auth/auth_service.dart';
import 'auth/token_service.dart';
import 'user/user_service.dart';
import 'user/profile_service.dart';
import 'follow/follow_service.dart';
import 'post/post_service.dart';
import 'event/event_service.dart'; // Yeni eklenen import
import 'notifications/notifications_service.dart';
import 'notifications/fcm_service.dart';
import 'search/search_service.dart';
import 'gamification_service.dart';
import 'chat/chat_service.dart';
import 'chat/chat_websocket_service.dart';
import 'chat/group_chat_service.dart';
import 'group/group_service.dart';
import 'location/location_service.dart';
import 'connection/connection_manager.dart';
import 'storage/supabase_storage_service.dart';
import '../config/supabase_config.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();

  // Global keys
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  
  // Tab navigation callback
  static Function(int)? onTabChange;

  // Services
  late final LocalStorage _localStorage;
  late final ApiClient _apiClient;
  late final TokenService _tokenService;
  late final AuthService _authService;
  late final UserService _userService;
  late final ProfileService _profileService;
  late final FollowService _followService;
  late final PostService _postService;
  late final EventService _eventService; // Yeni eklenen service
  late final NotificationsService _notificationService;
  late final FCMService _fcmService;
  late final SearchService _searchService;
  late final GamificationService _gamificationService;
  late final ChatService _chatService;
  late final ChatWebSocketService _chatWebSocketService;
  late final GroupChatService _groupChatService;
  late final GroupService _groupService;
  late final LocationService _locationService;
  late final ConnectionManager _connectionManager;
  late final SupabaseStorageService _supabaseStorageService;
  late final supabase_client.SupabaseClient _supabaseClient;

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

      // 0. Supabase client'ı ServiceLocator'dan al (main.dart'da zaten initialize edildi)
      // Supabase.instance.client kullanılacak

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

      // 9. Initialize event service
      instance._eventService = EventService(authService: instance._authService);

      // 10. Initialize notification service
      instance._notificationService = NotificationsService();

      // 11. Initialize FCM service
      instance._fcmService = FCMService();

      // 12. Initialize search service
      instance._searchService = SearchService(instance._localStorage);

      // 12. Initialize gamification service
      instance._gamificationService = GamificationService(instance._tokenService);

      // 13. Initialize chat service
      instance._chatService = ChatService();

      // 14. Initialize chat WebSocket service
      instance._chatWebSocketService = ChatWebSocketService();

      // 15. Initialize group chat service
      instance._groupChatService = GroupChatService();

      // 15. Initialize group service
      instance._groupService = GroupService(authService: instance._authService);

      // 16. Initialize location service
      instance._locationService = LocationService();

      // 17. Initialize connection manager
      instance._connectionManager = ConnectionManager();
      await instance._connectionManager.initialize();

      // 18. Initialize Supabase Storage service
      instance._supabaseStorageService = SupabaseStorageService();


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
      await _instance._localStorage.clearMemoryCache();
      
      // Cache'leri temizle
      _instance._apiClient.clearCache();
      _instance._authService.clearCache();
      _instance._postService.clearCache();
      _instance._userService.clearCache();
      _instance._notificationService.clearCache();
      _instance._chatService.clearCache();
      _instance._groupChatService.clearCache();
      _instance._searchService.clearCache();
      _instance._groupService.clearCache();
      _instance._eventService.clearCache();
      _instance._locationService.clearCache();
      _instance._connectionManager.dispose();
      
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
  static PostService get posts => _instance._postService; // Alias for convenience
  static EventService get event => _instance._eventService; // Yeni getter
  static NotificationsService get notification =>
      _instance._notificationService;
  static FCMService get fcm => _instance._fcmService;
  static SearchService get search => _instance._searchService;
  static GamificationService get gamification => _instance._gamificationService;
  static ChatService get chat => _instance._chatService;
  static ChatWebSocketService get chatWebSocket => _instance._chatWebSocketService;
  static GroupChatService get groupChat => _instance._groupChatService;
  static GroupService get group => _instance._groupService;
  static LocationService get location => _instance._locationService;
  static ConnectionManager get connection => _instance._connectionManager;
  static SupabaseStorageService get supabaseStorage => _instance._supabaseStorageService;
  static LocalStorage get storage => _instance._localStorage;

  // Supabase helper - Supabase.instance.client kullan
  static supabase_client.SupabaseClient get supabaseClient =>
      supabase_client.SupabaseClient(
        SupabaseConfig.supabaseUrl,
        SupabaseConfig.supabaseAnonKey,
      );

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
