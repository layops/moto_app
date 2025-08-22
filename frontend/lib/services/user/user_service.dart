import 'package:dio/dio.dart';
import '../http/api_client.dart';
import '../storage/local_storage.dart';
import '../http/api_exceptions.dart'; // Doğru import yolu

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
      'users/register/',
      {
        'username': username,
        'email': email,
        'password': password,
      },
    );
  }

  Future<String?> getCurrentUsername() async {
    return await _storage.getCurrentUsername();
  }

  Future<Response> updateProfile(
      String username, Map<String, dynamic> profileData) async {
    return await _apiClient.put(
      'users/$username/profile/',
      profileData,
    );
  }

  Future<Map<String, dynamic>?> getProfile(String username) async {
    try {
      final response = await _apiClient.get('users/$username/profile/');
      return response.data as Map<String, dynamic>?;
    } catch (e) {
      print('Profil getirme hatası: $e');
      return null;
    }
  }

  Future<List<dynamic>> getPosts(String username) async {
    try {
      final response = await _apiClient.get('users/$username/posts/');
      return response.data as List<dynamic>;
    } catch (e) {
      print('Gönderiler getirme hatası: $e');
      return [];
    }
  }

  Future<List<dynamic>> getMedia(String username) async {
    try {
      final response = await _apiClient.get('users/$username/media/');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      // Sadece DioException'ı yakala
      if (e.response?.statusCode == 500) {
        print('Medya endpointi sunucu hatası (500), boş liste döndürülüyor');
        return [];
      }
      print('Medya getirme hatası (DioException): ${e.message}');
      return [];
    } catch (e) {
      // Diğer tüm hataları yakala
      print('Medya getirme hatası (genel): $e');
      return [];
    }
  }

  Future<List<dynamic>> getEvents(String username) async {
    try {
      final response = await _apiClient.get('users/$username/events/');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      // Sadece DioException'ı yakala
      if (e.response?.statusCode == 500) {
        print(
            'Etkinlikler endpointi sunucu hatası (500), boş liste döndürülüyor');
        return [];
      }
      print('Etkinlikler getirme hatası (DioException): ${e.message}');
      return [];
    } catch (e) {
      // Diğer tüm hataları yakala
      print('Etkinlikler getirme hatası (genel): $e');
      return [];
    }
  }
}
