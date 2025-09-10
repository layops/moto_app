import 'package:dio/dio.dart';
import '../http/api_client.dart';
import '../auth/token_service.dart';

class FollowService {
  final ApiClient _apiClient;
  final TokenService _tokenService;

  FollowService(this._apiClient, this._tokenService);

  /// Kullanıcıyı takip et / takipten çıkar
  Future<bool> followToggleUser(String username) async {
    final token = await _tokenService.getToken();
    if (token == null) throw Exception('Kullanıcı girişi gerekli');

    try {
      final response = await _apiClient.post(
        'users/$username/follow-toggle/',
        {},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final detail = response.data['detail'] ?? '';
        return detail.contains('Takip edildi');
      } else {
        throw Exception('Takip işlemi başarısız: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Kullanıcı bulunamadı');
      }
      rethrow;
    }
  }

  /// Kullanıcının takipçilerini al
  Future<List<dynamic>> getFollowers(String username) async {
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
      if (e.response?.statusCode == 404) return [];
      rethrow;
    }
  }

  /// Kullanıcının takip ettiklerini al
  Future<List<dynamic>> getFollowing(String username) async {
    final token = await _tokenService.getToken();
    if (token == null) throw Exception('Kullanıcı girişi gerekli');

    try {
      print('🔍 FollowService - getFollowing çağrıldı, username: $username');
      final response = await _apiClient.get('users/$username/following/');
      print('🔍 FollowService - getFollowing response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final following = response.data as List<dynamic>;
        print('🔍 FollowService - Takip edilen kullanıcı sayısı: ${following.length}');
        for (var user in following) {
          print('🔍 FollowService - Takip edilen: ${user['username']}');
        }
        return following;
      } else {
        throw Exception('Takip edilenler alınamadı: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ FollowService - getFollowing hatası: ${e.message}');
      if (e.response?.statusCode == 404) return [];
      rethrow;
    }
  }

  /// Belirli bir kullanıcıyı takip edip etmediğini kontrol et
  Future<bool> isFollowingUser(String username) async {
    final followingList = await getFollowing(username);
    final tokenUsername = await _tokenService.getUsernameFromToken();
    return followingList.any((user) => user['username'] == username);
  }
}
