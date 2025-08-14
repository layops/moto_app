import 'package:dio/dio.dart';
import 'package:motoapp_frontend/config.dart';
import '../auth/auth_service.dart';

class EventService {
  final Dio _dio;
  final AuthService _authService;

  EventService({Dio? dio, required AuthService authService})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: kBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              contentType: 'application/json',
            )),
        _authService = authService;

  Options _authOptions(String? token) {
    if (token == null) return Options();
    return Options(headers: {'Authorization': 'Token $token'});
  }

  Future<List<dynamic>> fetchGroupEvents(int groupId) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Token bulunamadı. Lütfen giriş yapın.');

    try {
      final res = await _dio.get('groups/$groupId/events/',
          options: _authOptions(token));

      if (res.statusCode == 200) {
        return res.data as List<dynamic>;
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
    final token = await _authService.getToken();
    if (token == null) throw Exception('Token bulunamadı. Lütfen giriş yapın.');

    final payload = <String, dynamic>{
      'title': title,
      'description': description ?? '',
      'location': location ?? '',
      'start_time': startTime.toUtc().toIso8601String(),
      if (endTime != null) 'end_time': endTime.toUtc().toIso8601String(),
      if (participants != null) 'participants': participants,
    };

    try {
      final res = await _dio.post(
        'groups/$groupId/events/',
        data: payload,
        options: _authOptions(token),
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        return res.data as Map<String, dynamic>;
      } else {
        throw Exception('Etkinlik oluşturulamadı: ${res.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? e.message);
    }
  }
}
