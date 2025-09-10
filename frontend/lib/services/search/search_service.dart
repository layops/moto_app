import 'package:dio/dio.dart';
import '../http/api_client.dart';
import '../http/api_exceptions.dart';
import '../storage/local_storage.dart';

class SearchService {
  final ApiClient _apiClient;
  final LocalStorage _storage;

  SearchService(this._storage) : _apiClient = ApiClient(_storage);

  /// Kullanıcı arama
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      print('🔍 Frontend - Kullanıcı arama başlatılıyor: $query');
      final response = await _apiClient.get(
        'search/users/',
        queryParameters: {'q': query},
      );

      print('🔍 Frontend - API yanıtı: ${response.statusCode}');
      print('🔍 Frontend - API verisi: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        print('🔍 Frontend - Bulunan kullanıcı sayısı: ${data.length}');
        for (var user in data) {
          print('🔍 Frontend - Kullanıcı: ${user['username']} (ID: ${user['id']})');
        }
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Kullanıcı arama başarısız: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('🔍 Frontend - DioException: $e');
      throw ApiExceptions.fromDioError(e);
    } catch (e) {
      print('🔍 Frontend - Genel hata: $e');
      throw Exception('Kullanıcı arama hatası: $e');
    }
  }

  /// Grup arama
  Future<List<Map<String, dynamic>>> searchGroups(String query) async {
    try {
      final response = await _apiClient.get(
        'search/groups/',
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Grup arama başarısız: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw ApiExceptions.fromDioError(e);
    } catch (e) {
      throw Exception('Grup arama hatası: $e');
    }
  }

  /// Genel arama (hem kullanıcı hem grup)
  Future<Map<String, List<Map<String, dynamic>>>> searchAll(String query) async {
    try {
      // Her iki arama işlemini ayrı ayrı yap, biri başarısız olursa diğeri etkilenmesin
      List<Map<String, dynamic>> users = [];
      List<Map<String, dynamic>> groups = [];
      
      try {
        users = await searchUsers(query);
      } catch (e) {
        // Kullanıcı arama hatası, boş liste döndür
        users = [];
      }
      
      try {
        groups = await searchGroups(query);
      } catch (e) {
        // Grup arama hatası, boş liste döndür
        groups = [];
      }

      return {
        'users': users,
        'groups': groups,
      };
    } catch (e) {
      throw Exception('Genel arama hatası: $e');
    }
  }

  /// Arama geçmişi kaydetme
  Future<void> saveSearchHistory(String query) async {
    try {
      final history = await getSearchHistory();
      
      // Aynı sorguyu listeden kaldır (varsa)
      history.remove(query);
      
      // En başa ekle
      history.insert(0, query);
      
      // Maksimum 10 arama geçmişi tut
      if (history.length > 10) {
        history.removeRange(10, history.length);
      }
      
      await _storage.setString('search_history', history.join(','));
    } catch (e) {
      // Arama geçmişi kaydetme hatası kritik değil, sessizce geç
    }
  }

  /// Arama geçmişi getirme
  Future<List<String>> getSearchHistory() async {
    try {
      final historyString = await _storage.getString('search_history');
      if (historyString != null && historyString.isNotEmpty) {
        return historyString.split(',');
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Arama geçmişi temizleme
  Future<void> clearSearchHistory() async {
    try {
      await _storage.remove('search_history');
    } catch (e) {
      // Hata durumunda sessizce geç
    }
  }
}
