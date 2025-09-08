import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../auth/auth_service.dart';
import '../../config.dart';

class EventService {
  final AuthService authService;
  final Dio _dio = Dio();

  EventService({required this.authService});

  Future<List<dynamic>> fetchAllEvents() async {
    try {
      final token = await authService.getToken();
      if (token == null) {
        throw Exception('Authentication token not available');
      }
      
      final response = await _dio.get(
        '$kBaseUrl/api/events/',
        options: Options(
          headers: {
            'Authorization': 'Token $token',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );
      
      if (response.statusCode == 200) {
        return response.data ?? [];
      } else {
        throw Exception('Server returned status ${response.statusCode}: ${response.data}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response?.data;
        final errorMessage = errorData is Map
            ? errorData['detail'] ?? errorData['error'] ?? errorData.toString()
            : e.response?.data?.toString() ?? e.message;
        throw Exception('Failed to fetch events: $errorMessage');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<List<dynamic>> fetchGroupEvents(int groupId) async {
    try {
      final token = await authService.getToken();
      if (token == null) {
        throw Exception('Authentication token not available');
      }
      
      final response = await _dio.get(
        '$kBaseUrl/api/events/',
        queryParameters: {'group': groupId},
        options: Options(
          headers: {
            'Authorization': 'Token $token',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );
      
      if (response.statusCode == 200) {
        return response.data ?? [];
      } else {
        throw Exception('Server returned status ${response.statusCode}: ${response.data}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response?.data;
        final errorMessage = errorData is Map
            ? errorData['detail'] ?? errorData['error'] ?? errorData.toString()
            : e.response?.data?.toString() ?? e.message;
        throw Exception('Failed to fetch group events: $errorMessage');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
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
        '$kBaseUrl/api/events/',
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
        '$kBaseUrl/api/events/$eventId/join/',
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
        '$kBaseUrl/api/events/$eventId/participants/',
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
        '$kBaseUrl/api/events/$eventId/leave/',
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
