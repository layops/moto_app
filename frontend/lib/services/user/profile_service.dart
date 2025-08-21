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
      'profile_image': await MultipartFile.fromFile(
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
    final token = await _tokenService.getToken();
    if (token == null) throw Exception('Kullanıcı girişi gerekli');

    return await _apiClient.put(
      'profile/update/',
      profileData,
    );
  }

  // Profil bilgilerini çekme
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _apiClient.get('profile/');
    return response.data as Map<String, dynamic>;
  }

  // Kullanıcının gönderilerini çekme
  Future<List<Map<String, dynamic>>> getPosts() async {
    final response = await _apiClient.get('profile/posts/');
    return List<Map<String, dynamic>>.from(response.data);
  }

  // Kullanıcının medya içeriklerini çekme
  Future<List<Map<String, dynamic>>> getMedia() async {
    final response = await _apiClient.get('profile/media/');
    return List<Map<String, dynamic>>.from(response.data);
  }
}
