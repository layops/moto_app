import 'package:dio/dio.dart'; // Response sınıfı için
import '../http/api_client.dart';
import '../storage/local_storage.dart';

class UserService {
  final ApiClient _apiClient;
  final LocalStorage _storage;

  UserService(this._apiClient, this._storage);

  Future<Response> register({
    required String username,
    required String email,
    required String password,
  }) async {
    return await _apiClient.post(
      'register/', // URL path
      {
        // Request body (data) parametresi eklendi
        'username': username,
        'email': email,
        'password': password,
      },
    );
  }

  Future<String?> getCurrentUsername() async {
    return await _storage.getCurrentUsername();
  }

  // Kullanıcı bilgilerini güncelleme örneği
  Future<Response> updateProfile(Map<String, dynamic> profileData) async {
    return await _apiClient.post(
      'profile/update/',
      profileData,
    );
  }
}
