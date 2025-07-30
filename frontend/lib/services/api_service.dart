// frontend/lib/services/api_service.dart

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  late Dio _dio; // Dio istemcisini tutacak değişken
  final String _baseUrl =
      'http://172.19.34.247:8000/api/'; // Backend API'nizin temel URL'si

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 5), // Bağlantı zaman aşımı
      receiveTimeout: const Duration(seconds: 3), // Veri alma zaman aşımı
    ));

    // İstekleri göndermeden önce JWT token'ı eklemek için Interceptor ekle
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('authToken'); // Kaydedilmiş token'ı al

        if (token != null) {
          options.headers['Authorization'] =
              'Token $token'; // JWT token'ı başlığa ekle
        }
        return handler.next(options); // İsteği devam ettir
      },
      onError: (DioException e, handler) {
        // Hata durumunda loglama veya hata yönetimi yapabilirsiniz
        print('API Hatası: ${e.response?.statusCode} - ${e.message}');
        return handler.next(e); // Hatayı devam ettir
      },
    ));
  }

  // GET isteği için genel metod
  Future<Response> get(String path) async {
    return await _dio.get(path);
  }

  // POST isteği için genel metod
  Future<Response> post(String path, dynamic data) async {
    return await _dio.post(path, data: data);
  }

  // PUT isteği için genel metod
  Future<Response> put(String path, dynamic data) async {
    return await _dio.put(path, data: data);
  }

  // PATCH isteği için genel metod
  Future<Response> patch(String path, dynamic data) async {
    return await _dio.patch(path, data: data);
  }

  // DELETE isteği için genel metod
  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }

  // Kullanıcı giriş (login) işlemi
  Future<Response> login(String username, String password) async {
    // 'users/' kısmını kaldırdık, çünkü _baseUrl zaten '/api/' ile bitiyor
    // ve users.urls'de login endpoint'i doğrudan 'login/' olarak tanımlı.
    return await post('login/', {
      'username': username,
      'password': password,
    });
  }

  // Kullanıcı kayıt (register) işlemi
  Future<Response> register(
      String username, String email, String password) async {
    // Aynı şekilde 'users/' kısmını kaldırdık.
    return await post('register/', {
      'username': username,
      'email': email,
      'password': password,
    });
  }

  // Token'ı yerel depolamaya kaydet
  Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
    print('Auth token kaydedildi: $token');
  }

  // Token'ı yerel depolamadan sil
  Future<void> deleteAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    print('Auth token silindi.');
  }

  // Token'ı yerel depolamadan oku
  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }
}
