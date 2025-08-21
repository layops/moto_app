import 'package:dio/dio.dart';
import '../auth/auth_service.dart';

class GroupService {
  final Dio _dio;
  final AuthService _authService;

  GroupService({Dio? dio, required AuthService authService})
      : _dio = dio ?? Dio(),
        _authService = authService;

  Options _authOptions(String? token) {
    if (token == null) throw Exception('Token bulunamadı. Lütfen giriş yapın.');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<List<dynamic>> fetchUserGroups() async {
    final token = await _authService.getToken();
    final response = await _dio.get('groups/', options: _authOptions(token));
    return response.data as List<dynamic>;
  }
}
