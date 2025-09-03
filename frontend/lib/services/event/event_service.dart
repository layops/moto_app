import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../auth/auth_service.dart';

class EventService {
  final AuthService authService;
  final Dio _dio = Dio();

  EventService({required this.authService});

  Future<List<dynamic>> fetchAllEvents() async {
    try {
      final token = await authService.getToken();
      final response = await _dio.get(
        'https://spiride.onrender.com/api/events/',
        options: Options(
          headers: {
            'Authorization': 'Token $token',
          },
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to fetch events: ${e.message}');
    }
  }

  Future<List<dynamic>> fetchGroupEvents(int groupId) async {
    try {
      final token = await authService.getToken();
      final response = await _dio.get(
        'https://spiride.onrender.com/api/events/',
        queryParameters: {'group': groupId},
        options: Options(
          headers: {
            'Authorization': 'Token $token',
          },
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to fetch group events: ${e.message}');
    }
  }

  Future<void> createEvent({
    required String title,
    required String description,
    required String location,
    required DateTime startTime,
    DateTime? endTime,
    required bool isPublic,
    int? guestLimit,
    File? coverImageFile,
    int? groupId,
  }) async {
    try {
      final token = await authService.getToken();
      if (token == null) {
        throw Exception('Token not available');
      }

      // FormData oluştur
      final formData = FormData.fromMap({
        'title': title,
        'description': description,
        'location': location,
        'start_time': startTime.toUtc().toIso8601String(), // UTC formatında
        'is_public': isPublic.toString(), // String olarak gönder
        if (endTime != null) 'end_time': endTime.toUtc().toIso8601String(),
        if (guestLimit != null) 'guest_limit': guestLimit.toString(),
        if (groupId != null) 'group_id': groupId.toString(),
      });

      // Eğer resim dosyası varsa ekle
      if (coverImageFile != null) {
        final mimeType = lookupMimeType(coverImageFile.path);
        final fileExtension = mimeType?.split('/')[1] ?? 'jpg';

        formData.files.add(MapEntry(
          'cover_image',
          await MultipartFile.fromFile(
            coverImageFile.path,
            contentType: MediaType('image', fileExtension),
          ),
        ));
      }

      final response = await _dio.post(
        'https://spiride.onrender.com/api/events/',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Token $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode != 201) {
        throw Exception(
            'Failed to create event: ${response.statusCode} - ${response.data}');
      }
    } on DioException catch (e) {
      // Detaylı hata bilgisi
      final errorData = e.response?.data;
      final errorMessage = errorData is Map
          ? errorData['detail'] ?? errorData.toString()
          : e.message;

      throw Exception('Failed to create event: $errorMessage');
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  Future<Map<String, dynamic>> joinEvent(int eventId) async {
    try {
      final token = await authService.getToken();
      final response = await _dio.post(
        'https://spiride.onrender.com/api/events/$eventId/join/',
        options: Options(
          headers: {
            'Authorization': 'Token $token',
          },
        ),
      );
      return response.data; // Doğrudan event verisini döndür
    } on DioException catch (e) {
      throw Exception('Failed to join event: ${e.message}');
    }
  }

  Future<List<dynamic>> fetchEventParticipants(int eventId) async {
    try {
      final token = await authService.getToken();
      final response = await _dio.get(
        'https://spiride.onrender.com/api/events/$eventId/participants/',
        options: Options(headers: {'Authorization': 'Token $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to fetch participants: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> leaveEvent(int eventId) async {
    try {
      final token = await authService.getToken();
      final response = await _dio.post(
        'https://spiride.onrender.com/api/events/$eventId/leave/',
        options: Options(
          headers: {
            'Authorization': 'Token $token',
          },
        ),
      );
      return response.data; // Doğrudan event verisini döndür
    } on DioException catch (e) {
      throw Exception('Failed to leave event: ${e.message}');
    }
  }
}
