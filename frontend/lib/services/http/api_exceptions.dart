import 'package:dio/dio.dart';

class ApiExceptions implements Exception {
  final String message;

  ApiExceptions(this.message);

  factory ApiExceptions.fromDioError(DioException dioError) {
    switch (dioError.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiExceptions('Sunucu ile bağlantı zaman aşımına uğradı');
      case DioExceptionType.badResponse:
        return ApiExceptions(_handleError(dioError.response));
      case DioExceptionType.cancel:
        return ApiExceptions('İstek iptal edildi');
      default:
        return ApiExceptions('Ağ hatası oluştu');
    }
  }

  static String _handleError(Response? response) {
    if (response == null) return 'Bilinmeyen hata';

    switch (response.statusCode) {
      case 400:
        return 'Geçersiz istek';
      case 401:
        return 'Yetkisiz erişim';
      case 403:
        return 'Erişim reddedildi';
      case 404:
        return 'Kaynak bulunamadı';
      case 500:
        return 'Sunucu hatası';
      default:
        return 'Beklenmeyen hata (${response.statusCode})';
    }
  }

  @override
  String toString() => message;
}
