import 'package:dio/dio.dart';
import '../http/api_client.dart';
import '../auth/token_service.dart';

class FollowService {
  final ApiClient _apiClient;
  final TokenService _tokenService;

  FollowService(this._apiClient, this._tokenService);

  Future<void> followUser(int userId) async {
    final token = await _tokenService.getToken();
    if (token == null) throw Exception('Kullanıcı girişi gerekli');

    final response = await _apiClient.post(
      'users/$userId/follow/',
      {},
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Takip işlemi başarısız: ${response.statusCode}');
    }
  }

  Future<void> unfollowUser(int userId) async {
    final token = await _tokenService.getToken();
    if (token == null) throw Exception('Kullanıcı girişi gerekli');

    final response = await _apiClient.post(
      'users/$userId/unfollow/',
      {},
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Takipten çıkma işlemi başarısız: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getFollowers(int userId) async {
    final token = await _tokenService.getToken();
    if (token == null) throw Exception('Kullanıcı girişi gerekli');

    final response = await _apiClient.get(
      'users/$userId/followers/',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode == 200) {
      return response.data as List<dynamic>;
    } else {
      throw Exception('Takipçiler alınamadı: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getFollowing(int userId) async {
    final token = await _tokenService.getToken();
    if (token == null) throw Exception('Kullanıcı girişi gerekli');

    final response = await _apiClient.get(
      'users/$userId/following/',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode == 200) {
      return response.data as List<dynamic>;
    } else {
      throw Exception('Takip edilenler alınamadı: ${response.statusCode}');
    }
  }

  // Kullanıcı adı ile takipçi ve takip edilenleri getirme metodları
  Future<List<dynamic>> getFollowersByUsername(String username) async {
    final token = await _tokenService.getToken();
    if (token == null) throw Exception('Kullanıcı girişi gerekli');

    try {
      final response = await _apiClient.get(
        'users/$username/followers/',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        throw Exception('Takipçiler alınamadı: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 500) {
        print(
            'Takipçiler endpointi sunucu hatası (500), boş liste döndürülüyor');
        return [];
      }
      print('Takipçiler getirme hatası (DioException): ${e.message}');
      return [];
    } catch (e) {
      print('Takipçiler getirme hatası (genel): $e');
      return [];
    }
  }

  Future<List<dynamic>> getFollowingByUsername(String username) async {
    final token = await _tokenService.getToken();
    if (token == null) throw Exception('Kullanıcı girişi gerekli');

    try {
      final response = await _apiClient.get(
        'users/$username/following/',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        throw Exception('Takip edilenler alınamadı: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 500) {
        print(
            'Takip edilenler endpointi sunucu hatası (500), boş liste döndürülüyor');
        return [];
      }
      print('Takip edilenler getirme hatası (DioException): ${e.message}');
      return [];
    } catch (e) {
      print('Takip edilenler getirme hatası (genel): $e');
      return [];
    }
  }
}
