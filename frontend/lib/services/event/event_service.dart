import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../auth/auth_service.dart';
import '../../config.dart';

class EventService {
  final AuthService authService;
  final Dio _dio = Dio();
  
  // Cache için
  final Map<String, dynamic> _eventCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

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
            'Authorization': 'Bearer $token',
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
            'Authorization': 'Bearer $token',
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
    bool requiresApproval = false,
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
        'requires_approval': requiresApproval.toString(),
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
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode != 201) {
        throw Exception(
            'Failed to create event: ${response.statusCode} - ${response.data}');
      }
      
      // Event oluşturma sonrası cache'i temizle
      clearCache();
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

  Future<Map<String, dynamic>> joinEvent(int eventId, {String? message}) async {
    try {
      final token = await authService.getToken();
      
      // CSRF token'ı al
      final csrfResponse = await _dio.get('$kBaseUrl/api/csrf-token/');
      final csrfToken = csrfResponse.data['csrfToken'];
      
      final formData = FormData();
      if (message != null && message.isNotEmpty) {
        formData.fields.add(MapEntry('message', message));
      }
      
      final response = await _dio.post(
        '$kBaseUrl/api/events/$eventId/join/',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'X-CSRFToken': csrfToken,
          },
        ),
      );
      // Event katılım sonrası cache'i temizle
      clearCache();
      
      return response.data; // Doğrudan event verisini döndür
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map) {
          final errorMessage = errorData['error'] ?? e.message;
          final errorType = errorData['error_type'];
          
          // Özel hata mesajları
          switch (errorType) {
            case 'event_full':
              throw Exception('Etkinlik kontenjanı dolmuştur. Katılımcı sayısı: ${errorData['participant_count']}/${errorData['guest_limit']}');
            case 'already_joined':
              throw Exception('Zaten bu etkinliğe katılıyorsunuz.');
            case 'request_exists':
              final requestStatus = errorData['request_status'];
              switch (requestStatus) {
                case 'pending':
                  throw Exception('Bu etkinlik için zaten bir katılım isteği gönderdiniz. Onay bekleniyor.');
                case 'approved':
                  throw Exception('Bu etkinliğe zaten katılıyorsunuz.');
                case 'rejected':
                  throw Exception('Bu etkinlik için gönderdiğiniz istek reddedilmiş. Yeni bir istek gönderebilirsiniz.');
                default:
                  throw Exception(errorMessage);
              }
            default:
              throw Exception(errorMessage);
          }
        } else {
          throw Exception('Failed to join event: ${e.message}');
        }
      } else {
        throw Exception('Failed to join event: ${e.message}');
      }
    }
  }

  Future<List<dynamic>> fetchEventParticipants(int eventId) async {
    try {
      final token = await authService.getToken();
      final response = await _dio.get(
        '$kBaseUrl/api/events/$eventId/participants/',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to fetch participants: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> leaveEvent(int eventId) async {
    try {
      final token = await authService.getToken();
      
      // CSRF token'ı al
      final csrfResponse = await _dio.get('$kBaseUrl/api/csrf-token/');
      final csrfToken = csrfResponse.data['csrfToken'];
      
      final response = await _dio.post(
        '$kBaseUrl/api/events/$eventId/leave/',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'X-CSRFToken': csrfToken,
          },
        ),
      );
      // Event ayrılma sonrası cache'i temizle
      clearCache();
      
      return response.data; // Doğrudan event verisini döndür
    } on DioException catch (e) {
      throw Exception('Failed to leave event: ${e.message}');
    }
  }

  // Cache helper methods
  bool _isCacheValid(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }
  
  void clearCache() {
    _eventCache.clear();
    _cacheTimestamps.clear();
  }

  // Event request yönetimi
  Future<List<dynamic>> getEventJoinRequests(int eventId) async {
    try {
      final token = await authService.getToken();
      final url = '$kBaseUrl/api/events/$eventId/requests/';
      print('DEBUG: Event join requests URL: $url');
      
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      print('DEBUG: Event join requests response: ${response.statusCode}');
      return response.data as List<dynamic>;
    } catch (e) {
      throw Exception('Failed to get event join requests: $e');
    }
  }

  Future<void> handleJoinRequest(int eventId, int requestId, bool approved) async {
    try {
      final token = await authService.getToken();
      final endpoint = approved ? 'approve_request' : 'reject_request';
      await _dio.post(
        '$kBaseUrl/api/events/$eventId/$endpoint/',
        data: {
          'request_id': requestId,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
    } catch (e) {
      throw Exception('Failed to handle join request: $e');
    }
  }

  // EventRequest ID'sinden EventRequest bilgisini al
  Future<Map<String, dynamic>?> getEventRequestById(int eventRequestId) async {
    try {
      final token = await authService.getToken();
      final response = await _dio.get(
        '$kBaseUrl/api/event-requests/$eventRequestId/',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('EventRequest bilgisi alınamadı: $e');
      return null;
    }
  }

  // Eski metodlar (geriye uyumluluk için)
  Future<List<dynamic>> getEventRequests(int eventId) async {
    return getEventJoinRequests(eventId);
  }

  Future<void> approveEventRequest(int eventId, int requestId) async {
    await handleJoinRequest(eventId, requestId, true);
  }

  Future<void> rejectEventRequest(int eventId, int requestId) async {
    await handleJoinRequest(eventId, requestId, false);
  }
}
