import 'dart:io';
import 'package:dio/dio.dart';
import '../http/api_client.dart';
import '../auth/token_service.dart';

class ProfileService {
  final ApiClient _apiClient;
  // ignore: unused_field
  final TokenService _tokenService;

  ProfileService(this._apiClient, this._tokenService);

  Future<Response> uploadProfileImage(File imageFile, String username) async {
    final formData = FormData.fromMap({
      'profile_image': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'profile_$username.jpg',
      ),
    });

    return await _apiClient.post(
      'users/$username/profile/upload-photo/',
      formData,
    );
  }

  Future<Response> updateProfile(
      String username, Map<String, dynamic> profileData) async {
    return await _apiClient.put(
      'users/$username/profile/',
      profileData,
    );
  }

  Future<Map<String, dynamic>> getProfile(String username) async {
    final response = await _apiClient.get('users/$username/profile/');
    return response.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getPosts(String username) async {
    final response = await _apiClient.get('users/$username/posts/');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<Map<String, dynamic>>> getMedia(String username) async {
    final response = await _apiClient.get('users/$username/media/');
    return List<Map<String, dynamic>>.from(response.data);
  }
}
