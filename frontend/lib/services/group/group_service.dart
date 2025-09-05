import 'package:dio/dio.dart';
import 'dart:io';
import '../auth/auth_service.dart';
import '../../config.dart';

class GroupService {
  final Dio _dio;
  final AuthService _authService;

  GroupService({Dio? dio, required AuthService authService})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: kBaseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
            )),
        _authService = authService;

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
    
    // FormData oluştur
    FormData formData = FormData.fromMap({
      'name': name,
      'description': description,
    });
    
    // Profil fotoğrafı varsa ekle
    if (profilePicture != null) {
      formData.files.add(MapEntry(
        'profile_picture',
        await MultipartFile.fromFile(
          profilePicture.path,
          filename: profilePicture.path.split('/').last,
        ),
      ));
    }
    
    // Grup oluştur
    final response = await _dio.post(
      'groups/',
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'multipart/form-data',
        },
      ),
    );

    if (response.statusCode != 201) {
      throw Exception('Grup oluşturulamadı: ${response.statusCode}');
    }
  }

  /// Grup profil fotoğrafını güncelle
  Future<void> updateGroupProfilePicture(int groupId, File newProfilePicture) async {
    final token = await _authService.getToken();
    
    // FormData oluştur
    FormData formData = FormData.fromMap({
      'profile_picture': await MultipartFile.fromFile(
        newProfilePicture.path,
        filename: newProfilePicture.path.split('/').last,
      ),
    });
    
    // Grup profil fotoğrafını güncelle
    final response = await _dio.patch(
      'groups/$groupId/',
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'multipart/form-data',
        },
      ),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Profil fotoğrafı güncellenemedi: ${response.statusCode}');
    }
  }
}
