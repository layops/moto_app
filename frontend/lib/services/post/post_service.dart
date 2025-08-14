import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostService {
  final Dio _dio;

  PostService({Dio? dio}) : _dio = dio ?? Dio();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> createPost({required String content, File? file}) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) throw Exception('Lütfen giriş yapın.');

    FormData formData = FormData.fromMap({'content': content});

    if (file != null) {
      formData.files.add(MapEntry(
        'image',
        await MultipartFile.fromFile(file.path,
            filename: file.path.split('/').last),
      ));
    }

    final response = await _dio.post(
      'http://172.19.34.247:8000/api/posts/',
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
  }

  Future<List<dynamic>> fetchPosts(String token) async {
    final response = await _dio.get(
      'http://172.19.34.247:8000/api/posts/',
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
  }
}
