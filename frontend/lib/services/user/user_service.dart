import 'package:dio/dio.dart';
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
      'register/',
      {
        'username': username,
        'email': email,
        'password': password,
      },
    );
  }

  Future<String?> getCurrentUsername() async {
    return _storage.getCurrentUsername();
  }

  Future<Response> updateProfile(Map<String, dynamic> profileData) async {
    return await _apiClient.post(
      'profile/update/',
      profileData,
    );
  }

  Future<Map<String, dynamic>?> getProfile(String username) async {
    try {
      final response = await _apiClient.get('users/$username/profile/');
      return response.data as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>> getPosts(String username) async {
    try {
      final response = await _apiClient.get('users/$username/posts/');
      return response.data as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getMedia(String username) async {
    try {
      final response = await _apiClient.get('users/$username/media/');
      return response.data as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getEvents(String username) async {
    try {
      final response = await _apiClient.get('users/$username/events/');
      return response.data as List<dynamic>;
    } catch (e) {
      return [];
    }
  }
}
