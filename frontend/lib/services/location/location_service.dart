import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../service_locator.dart';

class LocationService {
  final String _baseUrl = '$kBaseUrl/api';
  
  // Konum takibi için
  StreamSubscription<Position>? _positionStream;
  Timer? _locationUpdateTimer;
  bool _isSharingLocation = false;
  
  // Cache için
  final Map<String, List<LocationShare>> _locationCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(seconds: 10);

  Future<String?> _getToken() async {
    return await ServiceLocator.token.getToken();
  }

  /// Konum izni kontrol et ve iste
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    
    return true;
  }

  /// Mevcut konumu al
  Future<Position?> getCurrentPosition() async {
    try {
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        throw Exception('Konum izni verilmedi');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      return position;
    } catch (e) {
      // print('Konum alınamadı: $e');
      return null;
    }
  }

  /// Konum paylaşımını başlat
  Future<void> startLocationSharing({
    String? rideId,
    String? groupId,
    String shareType = 'ride',
  }) async {
    if (_isSharingLocation) {
      await stopLocationSharing();
    }

    bool hasPermission = await requestLocationPermission();
    if (!hasPermission) {
      throw Exception('Konum izni verilmedi');
    }

    _isSharingLocation = true;

    // İlk konumu gönder
    await _sendLocationUpdate(rideId: rideId, groupId: groupId, shareType: shareType);

    // Konum takibini başlat (her 30 saniyede bir güncelle)
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // 50 metre değişiklikte güncelle
      ),
    ).listen(
      (Position position) {
        _sendLocationUpdate(
          rideId: rideId,
          groupId: groupId,
          shareType: shareType,
          position: position,
        );
      },
      onError: (error) {
        // print('Konum takibi hatası: $error');
      },
    );
  }

  /// Konum paylaşımını durdur
  Future<void> stopLocationSharing() async {
    _isSharingLocation = false;
    _positionStream?.cancel();
    _positionStream = null;
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
  }

  /// Konum güncellemesi gönder
  Future<void> _sendLocationUpdate({
    String? rideId,
    String? groupId,
    String shareType = 'ride',
    Position? position,
  }) async {
    try {
      final currentPosition = position ?? await getCurrentPosition();
      if (currentPosition == null) return;

      final token = await _getToken();
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/rides/location-shares/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'latitude': currentPosition.latitude,
          'longitude': currentPosition.longitude,
          'accuracy': currentPosition.accuracy,
          'speed': currentPosition.speed,
          'heading': currentPosition.heading,
          'share_type': shareType,
          'ride': rideId,
          'group': groupId,
          'is_active': true,
        }),
      );

      if (response.statusCode == 201) {
        // print('✅ Konum güncellendi: ${currentPosition.latitude}, ${currentPosition.longitude}');
      } else {
        // print('❌ Konum güncellenemedi: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // print('❌ Konum gönderme hatası: $e');
    }
  }

  /// Aktif konum paylaşımlarını getir
  Future<List<LocationShare>> getActiveLocationShares({
    String? rideId,
    String? groupId,
  }) async {
    final cacheKey = 'active_shares_${rideId ?? 'all'}_${groupId ?? 'all'}';
    
    // Cache kontrolü
    if (_isCacheValid(cacheKey) && _locationCache.containsKey(cacheKey)) {
      return _locationCache[cacheKey]!;
    }

    final token = await _getToken();
    if (token == null) {
      throw Exception('Token bulunamadı');
    }

    try {
      String url = '$_baseUrl/rides/location-shares/active_shares/';
      Map<String, String> queryParams = {};
      
      if (rideId != null) queryParams['ride_id'] = rideId;
      if (groupId != null) queryParams['group_id'] = groupId;
      
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final shares = (data as List)
            .map((json) => LocationShare.fromJson(json))
            .toList();
            
        // Cache'e kaydet
        _locationCache[cacheKey] = shares;
        _cacheTimestamps[cacheKey] = DateTime.now();
        
        return shares;
      } else {
        throw Exception('Konum paylaşımları alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Konum paylaşımları alınırken hata: $e');
    }
  }

  /// Konum paylaşımını durdur
  Future<void> stopLocationShare(int shareId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token bulunamadı');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/rides/location-shares/$shareId/stop_sharing/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Cache'i temizle
        _clearLocationCache();
      } else {
        throw Exception('Konum paylaşımı durdurulamadı: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Konum paylaşımı durdurulurken hata: $e');
    }
  }

  /// Kullanıcının konum paylaşımlarını getir
  Future<List<LocationShare>> getUserLocationShares() async {
    const cacheKey = 'user_shares';
    
    // Cache kontrolü
    if (_isCacheValid(cacheKey) && _locationCache.containsKey(cacheKey)) {
      return _locationCache[cacheKey]!;
    }

    final token = await _getToken();
    if (token == null) {
      throw Exception('Token bulunamadı');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/rides/location-shares/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final shares = (data as List)
            .map((json) => LocationShare.fromJson(json))
            .toList();
            
        // Cache'e kaydet
        _locationCache[cacheKey] = shares;
        _cacheTimestamps[cacheKey] = DateTime.now();
        
        return shares;
      } else {
        throw Exception('Konum paylaşımları alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Konum paylaşımları alınırken hata: $e');
    }
  }

  // Cache helper methods
  bool _isCacheValid(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }
  
  void _clearLocationCache() {
    _locationCache.clear();
    _cacheTimestamps.clear();
  }
  
  void clearCache() {
    _clearLocationCache();
  }

  /// Grup üyelerinin konumlarını getir
  Future<List<LocationShare>> getGroupMembersLocations(int groupId) async {
    final cacheKey = 'group_locations_$groupId';
    
    // Cache kontrolü
    if (_isCacheValid(cacheKey) && _locationCache.containsKey(cacheKey)) {
      return _locationCache[cacheKey]!;
    }

    final token = await _getToken();
    if (token == null) {
      throw Exception('Token bulunamadı');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/rides/location-shares/active_shares/?group_id=$groupId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final shares = (data as List)
            .map((json) => LocationShare.fromJson(json))
            .toList();
            
        // Cache'e kaydet
        _locationCache[cacheKey] = shares;
        _cacheTimestamps[cacheKey] = DateTime.now();
        
        return shares;
      } else {
        throw Exception('Grup üyelerinin konumları alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Grup üyelerinin konumları alınırken hata: $e');
    }
  }

  // Getters
  bool get isSharingLocation => _isSharingLocation;
}

/// Konum paylaşımı modeli
class LocationShare {
  final int id;
  final User user;
  final int? rideId;
  final int? groupId;
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
    this.rideId,
    this.groupId,
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
      rideId: json['ride'],
      groupId: json['group'],
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

/// Kullanıcı modeli (LocationShare için)
class User {
  final int id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? profilePicture;

  User({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.profilePicture,
  });

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return username;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      profilePicture: json['profile_picture'],
    );
  }
}

