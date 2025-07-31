// frontend/lib/services/api_service.dart

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:motoapp_frontend/config.dart'; // config.dart dosyasını import ediyoruz

class ApiService {
  late Dio _dio; // Dio istemcisini tutacak değişken
  final String _baseUrl =
      kBaseUrl; // Backend API'nizin temel URL'si config.dart'tan alınıyor.

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
    final response = await post('login/', {
      'username': username,
      'password': password,
    });
    // Başarılı giriş sonrası kullanıcı adını da kaydet
    if (response.statusCode == 200 &&
        response.data != null &&
        response.data.containsKey('username')) {
      await saveUsername(response.data['username']); // Kullanıcı adını kaydet
    }
    return response;
  }

  // Kullanıcı kayıt (register) işlemi
  Future<Response> register(
      String username, String email, String password) async {
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

  // Kullanıcı adını yerel depolamaya kaydet
  Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    print('Kullanıcı adı kaydedildi: $username');
  }

  // Token'ı yerel depolamadan sil
  Future<void> deleteAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('username'); // Kullanıcı adını da sil
    print('Auth token ve kullanıcı adı silindi.');
  }

  // Token'ı yerel depolamadan oku
  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // Kullanıcı adını yerel depolamadan oku
  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  // "Beni Hatırla" durumunu kaydet
  Future<void> saveRememberMe(bool rememberMe) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', rememberMe);
    print('Beni Hatırla durumu kaydedildi: $rememberMe');
  }

  // "Beni Hatırla" durumunu oku
  Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('rememberMe') ?? false; // Varsayılan olarak false
  }

  // Kaydedilmiş kullanıcı adını (beni hatırla açıksa) kaydet
  Future<void> saveRememberedUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rememberedUsername', username);
    print('Hatırlanan kullanıcı adı kaydedildi: $username');
  }

  // Kaydedilmiş kullanıcı adını oku
  Future<String?> getRememberedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('rememberedUsername');
  }

  // Kaydedilmiş kullanıcı adını sil
  Future<void> clearRememberedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('rememberedUsername');
    print('Hatırlanan kullanıcı adı silindi.');
  }
}
