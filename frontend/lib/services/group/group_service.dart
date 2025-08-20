import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config.dart';

class GroupService {
  final Dio dio = Dio(BaseOptions(
    baseUrl: kBaseUrl,
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
  ));

  Future<List<dynamic>> fetchUserGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception(
            'Kullanıcı oturumu bulunamadı. Lütfen yeniden giriş yapın.');
      }

      dio.options.headers = {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      };

      final response = await dio.get('groups/');

      if (response.statusCode == 200) {
        return response.data as List;
      } else {
        throw Exception(
            'HTTP ${response.statusCode} - ${response.statusMessage}');
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401) {
        throw Exception('Yetkisiz erişim. Lütfen yeniden giriş yapın.');
      } else {
        throw Exception('API isteği başarısız: ${e.message}');
      }
    }
  }
}
