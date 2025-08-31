import 'dart:io';
import 'package:dio/dio.dart';
import '../http/api_client.dart';
import '../auth/token_service.dart';

class ProfileService {
  final ApiClient _apiClient;
  final TokenService _tokenService;

  ProfileService(this._apiClient, this._tokenService);

  Future<Response> uploadProfileImage(File imageFile, String username) async {
    final formData = FormData.fromMap({
      'profile_picture': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'profile_$username.jpg',
      ),
    });

    return await _apiClient.post(
      'profile/upload-photo/',
      formData,
    );
  }

  Future<Response> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final username = await _tokenService.getUsernameFromToken();
      final currentUsername =
          username ?? await _tokenService.getCurrentUsername();
      if (currentUsername == null) {
        throw Exception('Kullanıcı adı bulunamadı. Lütfen tekrar giriş yapın.');
      }
      return await _apiClient.put(
        'users/$currentUsername/profile/',
        profileData,
      );
    } catch (e) {
      print('Profil güncelleme hatası: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProfile(String username) async {
    try {
      final response = await _apiClient.get('users/$username/profile/');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('Profil getirme hatası: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPosts(String username) async {
    try {
      final response = await _apiClient.get('users/$username/posts/');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('Gönderiler getirme hatası: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMedia(String username) async {
    try {
      final response = await _apiClient.get('users/$username/media/');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('Medya getirme hatası: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCurrentUserProfile() async {
    try {
      final username = await _tokenService.getUsernameFromToken();
      final currentUsername =
          username ?? await _tokenService.getCurrentUsername();
      if (currentUsername == null) {
        throw Exception('Kullanıcı adı bulunamadı');
      }
      return await getProfile(currentUsername);
    } catch (e) {
      print('Mevcut kullanıcı profili getirme hatası: $e');
      rethrow;
    }
  }
}
