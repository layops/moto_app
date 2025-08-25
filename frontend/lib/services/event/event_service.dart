// event_service.dart
import 'package:dio/dio.dart';
import '../auth/auth_service.dart';
import '../http/api_client.dart';

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

  // Tüm etkinlikleri getir
  Future<List<dynamic>> fetchAllEvents() async {
    final token = await _authService.getToken();
    final res = await _dio.get('events/', options: _authOptions(token));
    return res.data as List<dynamic>;
  }

  Future<List<dynamic>> fetchGroupEvents(int groupId) async {
    final token = await _authService.getToken();
    final res =
        await _dio.get('groups/$groupId/events/', options: _authOptions(token));
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createEvent({
    required int groupId,
    required String title,
    String? description,
    String? location,
    required DateTime startTime,
    DateTime? endTime,
    List<int>? participants,
  }) async {
    final token = await _authService.getToken();
    final payload = {
      'title': title,
      'description': description ?? '',
      'location': location ?? '',
      'start_time': startTime.toUtc().toIso8601String(),
      if (endTime != null) 'end_time': endTime.toUtc().toIso8601String(),
      if (participants != null) 'participants': participants,
    };
    final res = await _dio.post('groups/$groupId/events/',
        data: payload, options: _authOptions(token));
    return res.data as Map<String, dynamic>;
  }
}
