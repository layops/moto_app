// post_service.dart

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

  // createPost metodunu güncelleyin
  Future<void> createPost({
    required String content,
    File? file,
    int? groupPk, // groupPk'yi null olabilecek şekilde değiştirin
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

    // URL'yi groupPk'nin değerine göre dinamik olarak belirleyin
    String apiUrl = 'http://172.17.62.146:8000/api/';
    if (groupPk != null) {
      apiUrl += 'groups/$groupPk/posts/';
    } else {
      apiUrl += 'posts/';
    }

    final response = await _dio.post(
      apiUrl,
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

  // fetchPosts metodunu güncelleyin
  Future<List<dynamic>> fetchPosts(String token, {int? groupPk}) async {
    // URL'yi groupPk'nin değerine göre dinamik olarak belirleyin
    String apiUrl = 'http://172.17.62.146:8000/api/';
    if (groupPk != null) {
      apiUrl += 'groups/$groupPk/posts/';
    } else {
      apiUrl += 'posts/';
    }

    final response = await _dio.get(
      apiUrl,
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