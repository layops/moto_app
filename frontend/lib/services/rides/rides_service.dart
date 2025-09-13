import 'package:dio/dio.dart';
import '../http/api_client.dart';
import '../http/api_exceptions.dart';
import '../storage/local_storage.dart';

/// Rides API servisi
class RidesService {
  static final RidesService _instance = RidesService._internal();
  factory RidesService() => _instance;
  RidesService._internal();

  final ApiClient _apiClient = ApiClient(LocalStorage());

  /// Tüm yolculukları getir
  Future<List<Ride>> getRides({
    String? startLocation,
    String? rideType,
    String? privacyLevel,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startLocation != null) queryParams['start_location'] = startLocation;
      if (rideType != null) queryParams['ride_type'] = rideType;
      if (privacyLevel != null) queryParams['privacy_level'] = privacyLevel;

      final response = await _apiClient.get('/rides/', queryParameters: queryParams);
      
      return (response.data as List)
          .map((json) => Ride.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception('Yolculuklar alınamadı: ${e.message}');
    }
  }

  /// Kullanıcının yolculuklarını getir
  Future<List<Ride>> getMyRides() async {
    try {
      final response = await _apiClient.get('/rides/my_rides/');
      
      return (response.data as List)
          .map((json) => Ride.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception('Yolculuklar alınamadı: ${e.message}');
    }
  }

  /// Yolculuk detayını getir
  Future<Ride> getRide(int rideId) async {
    try {
      final response = await _apiClient.get('/rides/$rideId/');
      return Ride.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Yolculuklar alınamadı: ${e.message}');
    }
  }

  /// Yeni yolculuk oluştur
  Future<Ride> createRide(CreateRideRequest request) async {
    try {
      final response = await _apiClient.post('/rides/', request.toJson());
      return Ride.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Yolculuklar alınamadı: ${e.message}');
    }
  }

  /// Yolculuğa katıl
  Future<void> joinRide(int rideId) async {
    try {
      await _apiClient.post('/rides/$rideId/join/', {});
    } on DioException catch (e) {
      throw Exception('Yolculuklar alınamadı: ${e.message}');
    }
  }

  /// Yolculuktan ayrıl
  Future<void> leaveRide(int rideId) async {
    try {
      await _apiClient.post('/rides/$rideId/leave/', {});
    } on DioException catch (e) {
      throw Exception('Yolculuklar alınamadı: ${e.message}');
    }
  }

  /// Katılım isteğini onayla
  Future<void> approveRequest(int rideId, int requestId) async {
    try {
      await _apiClient.post('/rides/$rideId/approve_request/', {
        'request_id': requestId,
      });
    } on DioException catch (e) {
      throw Exception('Yolculuklar alınamadı: ${e.message}');
    }
  }

  /// Katılım isteğini reddet
  Future<void> rejectRequest(int rideId, int requestId) async {
    try {
      await _apiClient.post('/rides/$rideId/reject_request/', {
        'request_id': requestId,
      });
    } on DioException catch (e) {
      throw Exception('Yolculuklar alınamadı: ${e.message}');
    }
  }

  /// Yolculuğu tamamla
  Future<Ride> completeRide(int rideId, CompleteRideRequest request) async {
    try {
      final response = await _apiClient.post('/rides/$rideId/complete_ride/', request.toJson());
      return Ride.fromJson(response.data['ride']);
    } on DioException catch (e) {
      throw Exception('Yolculuklar alınamadı: ${e.message}');
    }
  }

  /// Favori rotaları getir
  Future<List<RouteFavorite>> getFavoriteRoutes() async {
    try {
      final response = await _apiClient.get('/route-favorites/');
      
      return (response.data as List)
          .map((json) => RouteFavorite.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception('Yolculuklar alınamadı: ${e.message}');
    }
  }

  /// Rotayı favorilere ekle/çıkar
  Future<void> toggleFavorite(int rideId) async {
    try {
      await _apiClient.post('/route-favorites/toggle_favorite/', {
        'ride_id': rideId,
      });
    } on DioException catch (e) {
      throw Exception('Yolculuklar alınamadı: ${e.message}');
    }
  }

  /// Rota şablonlarını getir
  Future<List<RouteTemplate>> getRouteTemplates({String? category}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;

      final response = await _apiClient.get('/route-templates/', queryParameters: queryParams);
      
      return (response.data as List)
          .map((json) => RouteTemplate.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception('Yolculuklar alınamadı: ${e.message}');
    }
  }

  /// Şablondan yolculuk oluştur
  Future<Ride> createRideFromTemplate(int templateId, CreateRideFromTemplateRequest request) async {
    try {
      final response = await _apiClient.post('/route-templates/$templateId/create_ride/', request.toJson());
      return Ride.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Yolculuklar alınamadı: ${e.message}');
    }
  }

  /// Aktif konum paylaşımlarını getir
  Future<List<LocationShare>> getActiveLocationShares({int? rideId, int? groupId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (rideId != null) queryParams['ride_id'] = rideId;
      if (groupId != null) queryParams['group_id'] = groupId;

      final response = await _apiClient.get('/location-shares/active_shares/', queryParameters: queryParams);
      
      return (response.data as List)
          .map((json) => LocationShare.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception('Yolculuklar alınamadı: ${e.message}');
    }
  }

  /// Konum paylaşımı başlat
  Future<LocationShare> startLocationShare(StartLocationShareRequest request) async {
    try {
      final response = await _apiClient.post('/location-shares/', request.toJson());
      return LocationShare.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Yolculuklar alınamadı: ${e.message}');
    }
  }

  /// Konum paylaşımını durdur
  Future<void> stopLocationShare(int locationShareId) async {
    try {
      await _apiClient.post('/location-shares/$locationShareId/stop_sharing/', {});
    } on DioException catch (e) {
      throw Exception('Yolculuklar alınamadı: ${e.message}');
    }
  }
}

/// Ride model sınıfı
class Ride {
  final int id;
  final String owner;
  final String title;
  final String description;
  final String startLocation;
  final String endLocation;
  final List<double>? startCoordinates;
  final List<double>? endCoordinates;
  final DateTime startTime;
  final DateTime? endTime;
  final DateTime? completedAt;
  final List<String> participants;
  final int? maxParticipants;
  final String rideType;
  final String privacyLevel;
  final double? distanceKm;
  final int? estimatedDurationMinutes;
  final bool isActive;
  final bool isFavorite;
  final int? group;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<RideRequest> pendingRequests;
  final String? routePolyline;
  final List<dynamic> waypoints;

  Ride({
    required this.id,
    required this.owner,
    required this.title,
    required this.description,
    required this.startLocation,
    required this.endLocation,
    this.startCoordinates,
    this.endCoordinates,
    required this.startTime,
    this.endTime,
    this.completedAt,
    required this.participants,
    this.maxParticipants,
    required this.rideType,
    required this.privacyLevel,
    this.distanceKm,
    this.estimatedDurationMinutes,
    required this.isActive,
    required this.isFavorite,
    this.group,
    required this.createdAt,
    required this.updatedAt,
    required this.pendingRequests,
    this.routePolyline,
    required this.waypoints,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'],
      owner: json['owner'],
      title: json['title'],
      description: json['description'] ?? '',
      startLocation: json['start_location'],
      endLocation: json['end_location'],
      startCoordinates: json['start_coordinates'] != null 
          ? List<double>.from(json['start_coordinates']) 
          : null,
      endCoordinates: json['end_coordinates'] != null 
          ? List<double>.from(json['end_coordinates']) 
          : null,
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      participants: List<String>.from(json['participants'] ?? []),
      maxParticipants: json['max_participants'],
      rideType: json['ride_type'],
      privacyLevel: json['privacy_level'],
      distanceKm: json['distance_km']?.toDouble(),
      estimatedDurationMinutes: json['estimated_duration_minutes'],
      isActive: json['is_active'],
      isFavorite: json['is_favorite'],
      group: json['group'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      pendingRequests: (json['pending_requests'] as List?)
          ?.map((req) => RideRequest.fromJson(req))
          .toList() ?? [],
      routePolyline: json['route_polyline'],
      waypoints: json['waypoints'] ?? [],
    );
  }
}

/// RideRequest model sınıfı
class RideRequest {
  final int id;
  final int ride;
  final User requester;
  final String status;
  final DateTime createdAt;

  RideRequest({
    required this.id,
    required this.ride,
    required this.requester,
    required this.status,
    required this.createdAt,
  });

  factory RideRequest.fromJson(Map<String, dynamic> json) {
    return RideRequest(
      id: json['id'],
      ride: json['ride'],
      requester: User.fromJson(json['requester']),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// User model sınıfı
class User {
  final int id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? profilePicture;

  User({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.email,
    this.profilePicture,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      profilePicture: json['profile_picture'],
    );
  }
}

/// RouteFavorite model sınıfı
class RouteFavorite {
  final int id;
  final Ride ride;
  final DateTime createdAt;

  RouteFavorite({
    required this.id,
    required this.ride,
    required this.createdAt,
  });

  factory RouteFavorite.fromJson(Map<String, dynamic> json) {
    return RouteFavorite(
      id: json['id'],
      ride: Ride.fromJson(json['ride']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// RouteTemplate model sınıfı
class RouteTemplate {
  final int id;
  final String name;
  final String description;
  final String category;
  final String routePolyline;
  final List<dynamic> waypoints;
  final String startLocation;
  final String endLocation;
  final double distanceKm;
  final int estimatedDurationMinutes;
  final int difficultyLevel;
  final bool isPublic;
  final User createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  RouteTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.routePolyline,
    required this.waypoints,
    required this.startLocation,
    required this.endLocation,
    required this.distanceKm,
    required this.estimatedDurationMinutes,
    required this.difficultyLevel,
    required this.isPublic,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RouteTemplate.fromJson(Map<String, dynamic> json) {
    return RouteTemplate(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      category: json['category'],
      routePolyline: json['route_polyline'],
      waypoints: json['waypoints'] ?? [],
      startLocation: json['start_location'],
      endLocation: json['end_location'],
      distanceKm: json['distance_km'].toDouble(),
      estimatedDurationMinutes: json['estimated_duration_minutes'],
      difficultyLevel: json['difficulty_level'],
      isPublic: json['is_public'],
      createdBy: User.fromJson(json['created_by']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

/// LocationShare model sınıfı
class LocationShare {
  final int id;
  final User user;
  final int? ride;
  final int? group;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final String shareType;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  LocationShare({
    required this.id,
    required this.user,
    this.ride,
    this.group,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.speed,
    this.heading,
    required this.shareType,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LocationShare.fromJson(Map<String, dynamic> json) {
    return LocationShare(
      id: json['id'],
      user: User.fromJson(json['user']),
      ride: json['ride'],
      group: json['group'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      accuracy: json['accuracy']?.toDouble(),
      speed: json['speed']?.toDouble(),
      heading: json['heading']?.toDouble(),
      shareType: json['share_type'],
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

/// Request sınıfları
class CreateRideRequest {
  final String title;
  final String description;
  final String startLocation;
  final String endLocation;
  final List<double>? startCoordinates;
  final List<double>? endCoordinates;
  final DateTime startTime;
  final DateTime? endTime;
  final int? maxParticipants;
  final String rideType;
  final String privacyLevel;
  final double? distanceKm;
  final int? estimatedDurationMinutes;
  final String? routePolyline;
  final List<dynamic>? waypoints;
  final int? group;

  CreateRideRequest({
    required this.title,
    required this.description,
    required this.startLocation,
    required this.endLocation,
    this.startCoordinates,
    this.endCoordinates,
    required this.startTime,
    this.endTime,
    this.maxParticipants,
    this.rideType = 'casual',
    this.privacyLevel = 'public',
    this.distanceKm,
    this.estimatedDurationMinutes,
    this.routePolyline,
    this.waypoints,
    this.group,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'start_location': startLocation,
      'end_location': endLocation,
      if (startCoordinates != null) 'start_coordinates': startCoordinates,
      if (endCoordinates != null) 'end_coordinates': endCoordinates,
      'start_time': startTime.toIso8601String(),
      if (endTime != null) 'end_time': endTime!.toIso8601String(),
      if (maxParticipants != null) 'max_participants': maxParticipants,
      'ride_type': rideType,
      'privacy_level': privacyLevel,
      if (distanceKm != null) 'distance_km': distanceKm,
      if (estimatedDurationMinutes != null) 'estimated_duration_minutes': estimatedDurationMinutes,
      if (routePolyline != null) 'route_polyline': routePolyline,
      if (waypoints != null) 'waypoints': waypoints,
      if (group != null) 'group': group,
    };
  }
}

class CompleteRideRequest {
  final double distance;
  final double maxSpeed;
  final int duration;

  CompleteRideRequest({
    required this.distance,
    required this.maxSpeed,
    required this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'distance': distance,
      'max_speed': maxSpeed,
      'duration': duration,
    };
  }
}

class CreateRideFromTemplateRequest {
  final String title;
  final String description;
  final DateTime startTime;
  final int? maxParticipants;
  final String privacyLevel;
  final int? groupId;

  CreateRideFromTemplateRequest({
    required this.title,
    required this.description,
    required this.startTime,
    this.maxParticipants,
    this.privacyLevel = 'public',
    this.groupId,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      if (maxParticipants != null) 'max_participants': maxParticipants,
      'privacy_level': privacyLevel,
      if (groupId != null) 'group_id': groupId,
    };
  }
}

class StartLocationShareRequest {
  final int? rideId;
  final int? groupId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final String shareType;

  StartLocationShareRequest({
    this.rideId,
    this.groupId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.speed,
    this.heading,
    this.shareType = 'ride',
  });

  Map<String, dynamic> toJson() {
    return {
      if (rideId != null) 'ride': rideId,
      if (groupId != null) 'group': groupId,
      'latitude': latitude,
      'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      if (speed != null) 'speed': speed,
      if (heading != null) 'heading': heading,
      'share_type': shareType,
    };
  }
}
