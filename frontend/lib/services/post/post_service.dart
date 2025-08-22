import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config.dart';

class PostService {
  final Dio _dio;

  PostService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: kBaseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
            ));

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> createPost({
    required String content,
    File? file,
    int? groupPk,
  }) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Lütfen giriş yapın.');
    }

    FormData formData = FormData.fromMap({'content': content});
    if (file != null) {
      formData.files.add(MapEntry(
        'image',
        await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      ));
    }

    // Slash sorununu düzeltmek için endpoint oluşturma
    final endpoint = groupPk != null ? 'groups/$groupPk/posts' : 'posts';

    try {
      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Token $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode != 201) {
        throw Exception('Post oluşturulamadı: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('API endpointi bulunamadı: $kBaseUrl/$endpoint');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception(
            'Sunucuya bağlanılamıyor. Lütfen internet bağlantınızı kontrol edin.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
            'Sunucuya bağlanılamıyor. Lütfen sunucunun çalıştığından emin olun.');
      } else {
        throw Exception('Post oluşturulurken hata oluştu: ${e.message}');
      }
    }
  }

  Future<List<dynamic>> fetchPosts(String token, {int? groupPk}) async {
    // Slash sorununu düzeltmek için endpoint oluşturma
    final endpoint = groupPk != null ? 'groups/$groupPk/posts' : 'posts';

    try {
      final response = await _dio.get(
        endpoint,
        options: Options(
          headers: {
            'Authorization': 'Token $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        throw Exception('Postlar alınamadı: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('API endpointi bulunamadı: $kBaseUrl/$endpoint');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception(
            'Sunucuya bağlanılamıyor. Lütfen internet bağlantınızı kontrol edin.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
            'Sunucuya bağlanılamıyor. Lütfen sunucunun çalıştığından emin olun.');
      } else {
        throw Exception('Postlar alınırken hata oluştu: ${e.message}');
      }
    }
  }
}
