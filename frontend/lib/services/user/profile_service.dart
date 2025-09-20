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

  /// Profil fotoğrafı yükleme (Yeni güvenli sistem)
  Future<Response> uploadProfileImage(File imageFile) async {
    try {
      // Yeni güvenli Supabase upload sistemini kullan
      final result = await ServiceLocator.supabaseStorage.uploadProfilePicture(imageFile);
      
      if (result.success) {
        // Başarılı yükleme sonrası cache'leri temizle
        final username = await ServiceLocator.user.getCurrentUsername();
        if (username != null) {
          await _clearProfileCache(username);
        }
        
        // Cache temizleme - hard refresh için timestamp ekle
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        print('🔥 Profile upload completed at: $timestamp');
        
        // Mock response oluştur (eski sistemle uyumluluk için)
        return Response(
          data: {
            'user': {
              'profile_picture': result.url,
              'profile_photo': result.url,
            }
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );
      } else {
        throw Exception(result.error ?? 'Upload başarısız');
      }
    } catch (e) {
      // Fallback: Eski sistemi dene
      try {
        return await _uploadProfileImageLegacy(imageFile);
      } catch (fallbackError) {
        throw Exception('Upload başarısız: $e');
      }
    }
  }

  /// Eski profil fotoğrafı yükleme (fallback)
  Future<Response> _uploadProfileImageLegacy(File imageFile) async {
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

      final response = await _apiClient.post(
        'users/$username/upload-photo/',
        formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      // Profil fotoğrafı yükleme sonrası cache'leri temizle
      if (response.statusCode == 200) {
        await _clearProfileCache(username);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Kapak fotoğrafı yükleme (Sadece Supabase Storage)
  Future<Response> uploadCoverImage(File imageFile) async {
    try {
      // Doğrudan Supabase Storage kullan
      final result = await ServiceLocator.supabaseStorage.uploadCoverPicture(imageFile);
      
        if (result.success) {
          // Backend'e confirm_upload çağrısı yap
          await _confirmUpload(
            uploadId: 'cover_${DateTime.now().millisecondsSinceEpoch}',
            filePath: result.url?.split('/').last ?? 'cover_image',
            bucket: 'cover_pictures',
            fileType: 'cover',
          );
          
          // Başarılı yükleme sonrası cache'leri temizle
          final username = await ServiceLocator.user.getCurrentUsername();
          if (username != null) {
            await _clearProfileCache(username);
          }
          
          // Cache temizleme - hard refresh için timestamp ekle
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        print('🔥 Cover upload completed at: $timestamp');
          
          return Response(
            data: {
              'user': {
                'profile_picture': result.url,
                'profile_photo': result.url,
              }
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          );
        } else {
          throw Exception(result.error ?? 'Upload başarısız');
        }
    } catch (e) {
      throw Exception('Upload başarısız: $e');
    }
  }


  /// Eski kapak fotoğrafı yükleme (fallback)
  Future<Response> _uploadCoverImageLegacy(File imageFile) async {
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

      final response = await _apiClient.post(
        'users/$username/upload-cover/',
        formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      // Kapak fotoğrafı yükleme sonrası cache'leri temizle
      if (response.statusCode == 200) {
        await _clearProfileCache(username);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Mevcut profil bilgilerini getirme
  Future<Map<String, dynamic>> getProfile(String username, {bool useCache = true}) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Oturum süresi doldu');
      }

      final response = await _apiClient.get('users/$username/profile/', useCache: useCache);
      final data = response.data as Map<String, dynamic>;

      if (data.containsKey('profile_picture') &&
          data['profile_picture'] != null) {
        data['profile_photo'] = data['profile_picture'];
        data['profile_photo_url'] = data['profile_picture'];
      }

      if (data.containsKey('cover_picture') && data['cover_picture'] != null) {
        data['cover_photo'] = data['cover_picture'];
        data['cover_photo_url'] = data['cover_picture'];
      }

      return data;
    } catch (e) {
      // print('Profil getirme hatası: $e');
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

      final response = await _apiClient.put(
        'users/$username/profile/',
        profileData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      // Profil güncelleme sonrası cache'leri temizle
      if (response.statusCode == 200) {
        await _clearProfileCache(username);
      }

      return response;
    } catch (e) {
      // print('Profil güncelleme hatası: $e');
      rethrow;
    }
  }

  /// Profil cache'ini temizle (public method)
  Future<void> clearProfileCache(String username) async {
    try {
      // UserService cache'ini temizle
      ServiceLocator.user.clearUserCache(username);
      
      // API Client cache'ini temizle - daha kapsamlı
      ServiceLocator.api.clearCacheForPath('users/$username/profile/');
      ServiceLocator.api.clearCacheForPath('users/$username/');
      
      // LocalStorage'daki profil verilerini temizle
      await ServiceLocator.storage.clearProfileData();
      
      // Memory cache'leri de temizle
      await ServiceLocator.storage.clearMemoryCache();
      
      // print('✅ ProfileService - Cache temizlendi: $username');
    } catch (e) {
      // print('❌ ProfileService - Cache temizleme hatası: $e');
    }
  }

  /// Backend'e confirm_upload çağrısı
  Future<void> _confirmUpload({
    required String uploadId,
    required String filePath,
    required String bucket,
    required String fileType,
  }) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) throw Exception('Token bulunamadı');

      await _apiClient.post(
        'users/confirm-upload/',
        {
          'upload_id': uploadId,
          'file_path': filePath,
          'bucket': bucket,
          'file_type': fileType,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      
      print('🔥 Confirm upload başarılı: $fileType');
    } catch (e) {
      print('🔥 Confirm upload hatası: $e');
      // Hata olsa da devam et
    }
  }

  /// Profil cache'ini temizle (private method - backward compatibility)
  Future<void> _clearProfileCache(String username) async {
    await clearProfileCache(username);
  }
}
