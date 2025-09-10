import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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
      final username = await ServiceLocator.user.getCurrentUsername();
      if (username == null) {
        throw Exception('Oturum süresi doldu');
      }

      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Oturum süresi doldu');
      }

      final ext = imageFile.path.split('.').last;

      final formData = FormData.fromMap({
        'profile_picture': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.$ext',
        ),
      });

      return await _apiClient.post(
        'users/$username/upload-photo/',
        formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } catch (e) {
      print('Profil fotoğrafı yükleme hatası: $e');
      rethrow;
    }
  }

  /// Kapak fotoğrafı yükleme
  Future<Response> uploadCoverImage(File imageFile) async {
    try {
      final username = await ServiceLocator.user.getCurrentUsername();
      if (username == null) {
        throw Exception('Oturum süresi doldu');
      }

      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Oturum süresi doldu');
      }

      final ext = imageFile.path.split('.').last;

      final formData = FormData.fromMap({
        'cover_picture': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'cover_${DateTime.now().millisecondsSinceEpoch}.$ext',
        ),
      });

      return await _apiClient.post(
        'users/$username/upload-cover/',
        formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } catch (e) {
      print('Kapak fotoğrafı yükleme hatası: $e');
      rethrow;
    }
  }

  /// Mevcut profil bilgilerini getirme
  Future<Map<String, dynamic>> getProfile(String username) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Oturum süresi doldu');
      }

      final response = await _apiClient.get('users/$username/profile/');
      final data = response.data as Map<String, dynamic>;

      if (data.containsKey('profile_picture') &&
          data['profile_picture'] != null) {
        data['profile_photo'] = data['profile_picture'];
      }

      if (data.containsKey('cover_picture') && data['cover_picture'] != null) {
        data['cover_photo'] = data['cover_picture'];
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
      // Önce token'dan kullanıcı adını almayı dene
      String? username = await _tokenService.getUsernameFromToken();

      // Token'dan alınamazsa localStorage'dan al
      if (username == null) {
        username = await ServiceLocator.user.getCurrentUsername();
      }

      if (username == null) {
        throw Exception('Kullanıcı adı bulunamadı. Lütfen tekrar giriş yapın.');
      }

      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Token bulunamadı. Lütfen tekrar giriş yapın.');
      }

      return await _apiClient.put(
        'users/$username/profile/',
        profileData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } catch (e) {
      debugPrint('Profil güncelleme hatası: $e');
      rethrow;
    }
  }
}
