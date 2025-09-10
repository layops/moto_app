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
      print('🔍 SearchService - Kullanıcı arama başlatıldı: "$query"');
      print('🔍 SearchService - Query uzunluğu: ${query.trim().length}');
      
      // Minimum 2 karakter kontrolü
      if (query.trim().length < 2) {
        print('🔍 SearchService - Query çok kısa, boş liste döndürülüyor');
        return [];
      }
      
      print('🔍 SearchService - API çağrısı yapılıyor: search/users/?q=${query.trim()}');
      
      final response = await _apiClient.get(
        'search/users/',
        queryParameters: {'q': query.trim()},
        useCache: false, // Arama sonuçları cache'lenmemeli
      );

      print('🔍 SearchService - API yanıtı alındı: ${response.statusCode}');
      print('🔍 SearchService - Response data: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        print('✅ SearchService - Kullanıcı arama başarılı: ${data.length} kullanıcı bulundu');
        print('✅ SearchService - Kullanıcı verileri: $data');
        return data.cast<Map<String, dynamic>>();
      } else {
        print('❌ SearchService - API yanıt hatası: ${response.statusCode}');
        print('❌ SearchService - Hata detayı: ${response.data}');
        throw Exception('Kullanıcı arama başarısız: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ SearchService - DioException: ${e.message}');
      print('❌ SearchService - DioException response: ${e.response?.data}');
      print('❌ SearchService - DioException status: ${e.response?.statusCode}');
      throw ApiExceptions.fromDioError(e);
    } catch (e) {
      print('❌ SearchService - Genel hata: $e');
      throw Exception('Kullanıcı arama hatası: $e');
    }
  }

  /// Grup arama
  Future<List<Map<String, dynamic>>> searchGroups(String query) async {
    try {
      print('🔍 SearchService - Grup arama başlatıldı: "$query"');
      print('🔍 SearchService - Query uzunluğu: ${query.trim().length}');
      
      // Minimum 2 karakter kontrolü
      if (query.trim().length < 2) {
        print('🔍 SearchService - Query çok kısa, boş liste döndürülüyor');
        return [];
      }
      
      print('🔍 SearchService - API çağrısı yapılıyor: search/groups/?q=${query.trim()}');
      
      final response = await _apiClient.get(
        'search/groups/',
        queryParameters: {'q': query.trim()},
        useCache: false, // Arama sonuçları cache'lenmemeli
      );

      print('🔍 SearchService - API yanıtı alındı: ${response.statusCode}');
      print('🔍 SearchService - Response data: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        print('✅ SearchService - Grup arama başarılı: ${data.length} grup bulundu');
        print('✅ SearchService - Grup verileri: $data');
        return data.cast<Map<String, dynamic>>();
      } else {
        print('❌ SearchService - API yanıt hatası: ${response.statusCode}');
        print('❌ SearchService - Hata detayı: ${response.data}');
        throw Exception('Grup arama başarısız: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ SearchService - DioException: ${e.message}');
      print('❌ SearchService - DioException response: ${e.response?.data}');
      print('❌ SearchService - DioException status: ${e.response?.statusCode}');
      throw ApiExceptions.fromDioError(e);
    } catch (e) {
      print('❌ SearchService - Genel hata: $e');
      throw Exception('Grup arama hatası: $e');
    }
  }

  /// Genel arama (hem kullanıcı hem grup)
  Future<Map<String, List<Map<String, dynamic>>>> searchAll(String query) async {
    try {
      print('🔍 SearchService - Genel arama başlatıldı: "$query"');
      
      // Her iki arama işlemini ayrı ayrı yap, biri başarısız olursa diğeri etkilenmesin
      List<Map<String, dynamic>> users = [];
      List<Map<String, dynamic>> groups = [];
      
      print('🔍 SearchService - Kullanıcı arama başlatılıyor...');
      try {
        users = await searchUsers(query);
        print('✅ SearchService - Kullanıcı arama tamamlandı: ${users.length} sonuç');
      } catch (e) {
        print('❌ SearchService - Kullanıcı arama hatası: $e');
        // Kullanıcı arama hatası, boş liste döndür
        users = [];
      }
      
      print('🔍 SearchService - Grup arama başlatılıyor...');
      try {
        groups = await searchGroups(query);
        print('✅ SearchService - Grup arama tamamlandı: ${groups.length} sonuç');
      } catch (e) {
        print('❌ SearchService - Grup arama hatası: $e');
        // Grup arama hatası, boş liste döndür
        groups = [];
      }

      final result = {
        'users': users,
        'groups': groups,
      };
      
      print('✅ SearchService - Genel arama tamamlandı: ${users.length} kullanıcı, ${groups.length} grup');
      return result;
    } catch (e) {
      print('❌ SearchService - Genel arama hatası: $e');
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
