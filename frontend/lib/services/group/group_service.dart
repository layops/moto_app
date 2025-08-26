import 'package:dio/dio.dart';
import '../auth/auth_service.dart';
import '../../config.dart'; // config.dart dosyasını import edin

class GroupService {
  final Dio _dio;
  final AuthService _authService;

  GroupService({Dio? dio, required AuthService authService})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: kBaseUrl, // config.dart'daki kBaseUrl kullanılıyor
              connectTimeout: const Duration(seconds: 30), // 30 saniye
              receiveTimeout: const Duration(seconds: 30), // 30 saniye
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

  Future<void> createGroup(String name, String description) async {
    final token = await _authService.getToken();
    final response = await _dio.post(
      'groups/',
      data: {
        'name': name,
        'description': description,
      },
      options: _authOptions(token),
    );

    if (response.statusCode != 201) {
      throw Exception('Grup oluşturulamadı: ${response.statusCode}');
    }
  }
}
