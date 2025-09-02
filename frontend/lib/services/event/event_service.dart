import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../auth/auth_service.dart';

class EventService {
  final Dio _dio;
  final AuthService _authService;

  EventService({required AuthService authService})
      : _dio = authService.apiClient.dio,
        _authService = authService;

  Options _authOptions(String? token) {
    if (token == null) throw Exception('Token bulunamadı. Lütfen giriş yapın.');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is Map && data.containsKey('results')) {
      return (data['results'] as List).cast<dynamic>();
    }
    if (data is List) return data;
    return [];
  }

  // Tüm etkinlikleri çek
  Future<List<dynamic>> fetchAllEvents() async {
    final token = await _authService.getToken();
    final res = await _dio.get(
      'events/',
      options: _authOptions(token),
    );
    return _extractList(res.data);
  }

  // Grup etkinliklerini çek
  Future<List<dynamic>> fetchGroupEvents(int groupId) async {
    final token = await _authService.getToken();
    if (groupId <= 0) return [];
    final res = await _dio.get(
      'events/groups/$groupId/events/',
      options: _authOptions(token),
    );
    return _extractList(res.data);
  }

  // Yeni etkinlik oluştur
  Future<Map<String, dynamic>> createEvent({
    int? groupId,
    required String title,
    String? description,
    String? location,
    required DateTime startTime,
    DateTime? endTime,
    List<int>? participants,
    bool? isPublic,
    int? guestLimit,
    File? coverImageFile, // eklendi
  }) async {
    final token = await _authService.getToken();

    FormData formData = FormData.fromMap({
      'title': title,
      'description': description ?? '',
      'location': location ?? '',
      'start_time': startTime.toUtc().toIso8601String(),
      if (endTime != null) 'end_time': endTime.toUtc().toIso8601String(),
      if (participants != null) 'participants': participants,
      if (groupId != null && groupId > 0) 'group_id': groupId,
      if (isPublic != null) 'is_public': isPublic,
      if (guestLimit != null) 'guest_limit': guestLimit,
      if (coverImageFile != null)
        'cover_image': await MultipartFile.fromFile(
          coverImageFile.path,
          filename: coverImageFile.path.split('/').last,
          contentType: MediaType('image', 'jpeg'),
        ),
    });

    Response res;
    if (groupId != null && groupId > 0) {
      res = await _dio.post(
        'groups/$groupId/events/',
        data: formData,
        options: _authOptions(token),
      );
    } else {
      res = await _dio.post(
        'events/',
        data: formData,
        options: _authOptions(token),
      );
    }

    return (res.data as Map).cast<String, dynamic>();
  }

  // Etkinlik güncelle
  Future<Map<String, dynamic>> updateEvent({
    required int eventId,
    int? groupId,
    String? title,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    List<int>? participants,
    bool? isPublic,
    int? guestLimit,
    File? coverImageFile,
  }) async {
    final token = await _authService.getToken();

    FormData formData = FormData.fromMap({
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (location != null) 'location': location,
      if (startTime != null) 'start_time': startTime.toUtc().toIso8601String(),
      if (endTime != null) 'end_time': endTime.toUtc().toIso8601String(),
      if (participants != null) 'participants': participants,
      if (isPublic != null) 'is_public': isPublic,
      if (guestLimit != null) 'guest_limit': guestLimit,
      if (coverImageFile != null)
        'cover_image': await MultipartFile.fromFile(
          coverImageFile.path,
          filename: coverImageFile.path.split('/').last,
          contentType: MediaType('image', 'jpeg'),
        ),
    });

    Response res;
    if (groupId != null && groupId > 0) {
      res = await _dio.patch(
        'groups/$groupId/events/$eventId/',
        data: formData,
        options: _authOptions(token),
      );
    } else {
      res = await _dio.patch(
        'events/$eventId/',
        data: formData,
        options: _authOptions(token),
      );
    }

    return (res.data as Map).cast<String, dynamic>();
  }

  // Etkinliğe katıl
  Future<Map<String, dynamic>> joinEvent(int eventId) async {
    final token = await _authService.getToken();
    final res = await _dio.patch(
      'events/$eventId/join/',
      options: _authOptions(token),
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  // Etkinlikten ayrıl
  Future<Map<String, dynamic>> leaveEvent(int eventId) async {
    final token = await _authService.getToken();
    final res = await _dio.patch(
      'events/$eventId/leave/',
      options: _authOptions(token),
    );
    return (res.data as Map).cast<String, dynamic>();
  }
}
