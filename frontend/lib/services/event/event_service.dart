import 'package:dio/dio.dart';
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
    if (data is Map && data.containsKey('results'))
      return (data['results'] as List).cast<dynamic>();
    if (data is List) return data;
    return [];
  }

  Future<List<dynamic>> fetchAllEvents() async {
    final token = await _authService.getToken();
    final res = await _dio.get('events/', options: _authOptions(token));
    return _extractList(res.data);
  }

  Future<List<dynamic>> fetchGroupEvents(int groupId) async {
    final token = await _authService.getToken();
    final res =
        await _dio.get('groups/$groupId/events/', options: _authOptions(token));
    return _extractList(res.data);
  }

  Future<Map<String, dynamic>> createEvent({
    int? groupId,
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
      if (groupId != null) 'group_id': groupId,
    };

    Response res;
    if (groupId != null) {
      res = await _dio.post('groups/$groupId/events/',
          data: payload, options: _authOptions(token));
    } else {
      res = await _dio.post('events/',
          data: payload, options: _authOptions(token));
    }
    return (res.data as Map).cast<String, dynamic>();
  }
}
