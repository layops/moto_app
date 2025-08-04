import 'dart:io';
import 'package:dio/dio.dart';
import '../http/api_client.dart';
import '../auth/token_service.dart'; // Doğru import yolu

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
}
