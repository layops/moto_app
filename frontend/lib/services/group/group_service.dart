import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// services/group/group_service.dart

class GroupService {
  final Dio dio = Dio(BaseOptions(
    baseUrl: 'http://172.19.34.247:8000/',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<List<dynamic>> fetchUserGroups() async {
    try {
      // Token'ı SharedPreferences'ten al
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception(
            'Kullanıcı oturumu bulunamadı. Lütfen yeniden giriş yapın.');
      }

      // Token'ı header'a ekle
      dio.options.headers = {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      };

      final response = await dio.get('api/groups/');

      if (response.statusCode == 200) {
        return response.data as List;
      } else {
        throw Exception(
            'HTTP ${response.statusCode} - ${response.statusMessage}');
      }
    } on DioException catch (e) {
      // Daha detaylı hata mesajı
      final statusCode = e.response?.statusCode;

      if (statusCode == 401) {
        throw Exception('Yetkisiz erişim. Lütfen yeniden giriş yapın.');
      } else {
        throw Exception('API isteği başarısız: ${e.message}');
      }
    }
  }
}
