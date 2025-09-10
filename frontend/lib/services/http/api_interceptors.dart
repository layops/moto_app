import 'package:dio/dio.dart';
import '../storage/local_storage.dart';
import 'package:motoapp_frontend/services/service_locator.dart';

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
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 || err.response?.statusCode == 403) {
      // Token geçersiz veya süresi dolmuşsa, logout yap
      await ServiceLocator.auth.logout();
    }
    handler.next(err);
  }
}
