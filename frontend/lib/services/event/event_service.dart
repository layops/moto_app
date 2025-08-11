import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:motoapp_frontend/config.dart';

class EventService {
  final Dio _dio;

  EventService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: kBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                contentType: 'application/json',
              ),
            );

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') ?? prefs.getString('token');
  }

  Options _authOptions(String? token) {
    if (token == null) return Options();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<List<dynamic>> fetchGroupEvents(int groupId) async {
    try {
      final token = await _getToken();
      final res = await _dio.get('/api/groups/$groupId/events/',
          options: _authOptions(token));
      if (res.statusCode == 200) {
        return (res.data as List<dynamic>);
      } else {
        throw Exception('Etkinlikler alınamadı: ${res.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? e.message);
    }
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
    try {
      final token = await _getToken();
      final payload = <String, dynamic>{
        'title': title,
        'description': description ?? '',
        'location': location ?? '',
        'start_time': startTime.toUtc().toIso8601String(),
        if (endTime != null) 'end_time': endTime.toUtc().toIso8601String(),
        if (participants != null) 'participants': participants,
      };

      final res = await _dio.post(
        '/api/groups/$groupId/events/',
        data: payload,
        options: _authOptions(token),
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        return (res.data as Map<String, dynamic>);
      } else {
        throw Exception('Etkinlik oluşturulamadı: ${res.statusCode}');
      }
    } on DioException catch (e) {
      final err = e.response?.data ?? e.message;
      throw Exception(err);
    }
  }
}
