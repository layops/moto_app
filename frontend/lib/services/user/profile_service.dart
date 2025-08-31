import 'dart:io';
import 'package:dio/dio.dart';
import 'package:motoapp_frontend/services/service_locator.dart';
import '../http/api_client.dart';
import '../auth/token_service.dart';

class ProfileService {
  final ApiClient _apiClient;
  final TokenService _tokenService;

  ProfileService(this._apiClient, this._tokenService);

  /// Profil fotoğrafı yükleme
  Future<Response> uploadProfileImage(File imageFile) async {
    try {
      // Kullanıcı adını al
      final username = await ServiceLocator.user.getCurrentUsername();
      if (username == null) {
        throw Exception('Kullanıcı adı bulunamadı');
      }

      // Token al
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Kullanıcı tokeni bulunamadı');
      }

      // FormData hazırla
      final formData = FormData.fromMap({
        'profile_picture': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      // API isteği gönder
      return await _apiClient.post(
        'users/$username/upload-photo/',
        formData,
        options: Options(
          headers: {
            'Authorization': 'Token $token',
          },
        ),
      );
    } catch (e) {
      print('Profil fotoğrafı yükleme hatası: $e');
      rethrow;
    }
  }

  /// Mevcut profil bilgilerini getirme
  Future<Map<String, dynamic>> getProfile(String username) async {
    try {
      final response = await _apiClient.get('users/$username/profile/');
      final data = response.data as Map<String, dynamic>;

      // Backend'den gelen alan adı 'profile_picture'
      if (data.containsKey('profile_picture') &&
          data['profile_picture'] != null) {
        data['profile_photo'] = data['profile_picture'];
      }

      return data;
    } catch (e) {
      print('Profil getirme hatası: $e');
      rethrow;
    }
  }

  /// Profil güncelleme
  Future<Response> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final username = await _tokenService.getUsernameFromToken();
      if (username == null) {
        throw Exception('Kullanıcı adı bulunamadı');
      }

      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Kullanıcı tokeni bulunamadı');
      }

      return await _apiClient.put(
        'users/$username/profile/',
        profileData,
        options: Options(
          headers: {
            'Authorization': 'Token $token',
          },
        ),
      );
    } catch (e) {
      print('Profil güncelleme hatası: $e');
      rethrow;
    }
  }
}
