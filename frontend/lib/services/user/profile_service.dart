import 'dart:io';
import 'package:dio/dio.dart';
import 'package:motoapp_frontend/services/service_locator.dart';
import '../http/api_client.dart';
import '../auth/token_service.dart';

class ProfileService {
  final ApiClient _apiClient;
  final TokenService _tokenService;

  ProfileService(this._apiClient, this._tokenService);

  /// Profil fotoğrafı yükleme - ENDPOINT TAM DÜZELTİLDİ
  Future<Response> uploadProfileImage(File imageFile) async {
    try {
      // Önce mevcut kullanıcı adını al
      final username = await ServiceLocator.user.getCurrentUsername();
      if (username == null) {
        throw Exception('Kullanıcı adı bulunamadı');
      }

      final formData = FormData.fromMap({
        'profile_picture': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      // Kullanıcı adını URL'ye ekle
      return await _apiClient.post(
        'users/$username/upload-photo/', // Kullanıcı adını URL'ye ekledik
        formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
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

      // Profil fotoğrafı URL'sini tam yola çevir
      // Düzeltme: Backend'den gelen alan adı 'profile_picture'
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

      return await _apiClient.put(
        'users/$username/profile/',
        profileData,
      );
    } catch (e) {
      print('Profil güncelleme hatası: $e');
      rethrow;
    }
  }
}
