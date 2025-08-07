import 'package:dio/dio.dart';
import '../storage/local_storage.dart';

class ApiInterceptors extends Interceptor {
  final LocalStorage _storage;

  ApiInterceptors(this._storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = _storage.getAuthToken();
    if (token != null) {
      options.headers['Authorization'] = 'Token $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await _storage.removeAuthToken(); // removeAuthToken kullanıyoruz
      await _storage.removeCurrentUsername();
    }
    handler.next(err);
  }
}
