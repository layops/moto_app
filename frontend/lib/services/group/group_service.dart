import 'package:dio/dio.dart';
import 'dart:io';
import '../auth/auth_service.dart';
import '../storage/supabase_storage_service.dart';
import '../../config.dart'; // config.dart dosyasını import edin

class GroupService {
  final Dio _dio;
  final AuthService _authService;
  final SupabaseStorageService _storageService;

  GroupService({Dio? dio, required AuthService authService})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: kBaseUrl, // config.dart'daki kBaseUrl kullanılıyor
              connectTimeout: const Duration(seconds: 30), // 30 saniye
              receiveTimeout: const Duration(seconds: 30), // 30 saniye
            )),
        _authService = authService,
        _storageService = SupabaseStorageService();

  Options _authOptions(String? token) {
    if (token == null) throw Exception('Token bulunamadı. Lütfen giriş yapın.');
    return Options(headers: {'Authorization': 'Token $token'});
  }

  Future<List<dynamic>> fetchUserGroups() async {
    final token = await _authService.getToken();
    final response = await _dio.get('groups/', options: _authOptions(token));
    return response.data as List<dynamic>;
  }

  Future<void> createGroup(String name, String description, {File? profilePicture}) async {
    final token = await _authService.getToken();
    
    // Profil fotoğrafı varsa önce yükle
    String? profilePictureUrl;
    if (profilePicture != null) {
      // Dosya validasyonu
      final validationError = _storageService.validateImageFile(profilePicture);
      if (validationError != null) {
        throw Exception(validationError);
      }
      
      profilePictureUrl = await _storageService.uploadGroupProfilePicture(profilePicture);
    }
    
    // Grup oluştur
    final response = await _dio.post(
      'groups/',
      data: {
        'name': name,
        'description': description,
        if (profilePictureUrl != null) 'profile_picture_url': profilePictureUrl,
      },
      options: _authOptions(token),
    );

    if (response.statusCode != 201) {
      // Eğer grup oluşturulamadıysa ve fotoğraf yüklendiyse, fotoğrafı sil
      if (profilePictureUrl != null) {
        try {
          await _storageService.deleteGroupProfilePicture(profilePictureUrl);
        } catch (e) {
          // Fotoğraf silme hatası kritik değil
        }
      }
      throw Exception('Grup oluşturulamadı: ${response.statusCode}');
    }
  }

  /// Grup profil fotoğrafını güncelle
  Future<void> updateGroupProfilePicture(int groupId, File newProfilePicture) async {
    final token = await _authService.getToken();
    
    // Dosya validasyonu
    final validationError = _storageService.validateImageFile(newProfilePicture);
    if (validationError != null) {
      throw Exception(validationError);
    }
    
    // Mevcut grup bilgilerini al
    final groupResponse = await _dio.get(
      'groups/$groupId/',
      options: _authOptions(token),
    );
    
    if (groupResponse.statusCode != 200) {
      throw Exception('Grup bilgileri alınamadı');
    }
    
    final groupData = groupResponse.data;
    final oldProfilePictureUrl = groupData['profile_picture_url'] as String?;
    
    // Yeni fotoğrafı yükle
    final newProfilePictureUrl = await _storageService.uploadGroupProfilePicture(newProfilePicture);
    
    try {
      // Grup bilgilerini güncelle
      final updateResponse = await _dio.patch(
        'groups/$groupId/',
        data: {
          'profile_picture_url': newProfilePictureUrl,
        },
        options: _authOptions(token),
      );
      
      if (updateResponse.statusCode != 200) {
        throw Exception('Profil fotoğrafı güncellenemedi');
      }
      
      // Eski fotoğrafı sil
      if (oldProfilePictureUrl != null && oldProfilePictureUrl.isNotEmpty) {
        await _storageService.deleteGroupProfilePicture(oldProfilePictureUrl);
      }
    } catch (e) {
      // Güncelleme başarısız olursa yeni fotoğrafı sil
      try {
        await _storageService.deleteGroupProfilePicture(newProfilePictureUrl);
      } catch (deleteError) {
        // Fotoğraf silme hatası kritik değil
      }
      rethrow;
    }
  }
}
