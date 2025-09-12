import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/map_state.dart';

/// Arama servisini yöneten sınıf
class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  Timer? _searchDebounce;

  /// Konum arama yap
  Future<List<SearchResult>> searchLocation(String query) async {
    if (query.trim().isEmpty || query.length < 3) {
      return [];
    }

    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {
          'q': query,
          'format': 'json',
          'limit': '5',
          'addressdetails': '1',
          'countrycodes': 'tr',
          'extratags': '0', // Disable extra tags for performance
          'namedetails': '0', // Disable name details for performance
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'MotoApp/1.0 (location search)',
          'Accept': 'application/json',
          'Connection': 'keep-alive',
        },
      ).timeout(const Duration(seconds: 8)); // Reduced timeout

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final results = data.map((item) => SearchResult.fromJson(item)).toList();
        
        // Arama geçmişine kaydet
        await _saveSearchHistory(query);
        
        return results;
      } else if (response.statusCode == 429) {
        throw SearchServiceException('Çok hızlı arama yapıldı. Lütfen bekleyin.');
      } else {
        throw SearchServiceException('Arama sırasında hata oluştu');
      }
    } on http.ClientException {
      throw SearchServiceException('İnternet bağlantınızı kontrol edin.');
    } catch (e) {
      throw SearchServiceException('Arama yapılamadı: ${e.toString()}');
    }
  }

  /// Debounced arama
  void searchWithDebounce(String query, Function(List<SearchResult>) onResults) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final results = await searchLocation(query);
        onResults(results);
      } catch (e) {
        onResults([]);
      }
    });
  }

  /// Arama geçmişini kaydet
  Future<void> _saveSearchHistory(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('search_history') ?? [];
      
      // Aynı sorguyu kaldır ve başa ekle
      history.remove(query);
      history.insert(0, query);
      
      // Maksimum 10 öğe tut
      if (history.length > 10) {
        history.removeRange(10, history.length);
      }
      
      await prefs.setStringList('search_history', history);
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  /// Arama geçmişini yükle
  Future<List<String>> loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('search_history') ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Arama geçmişini temizle
  Future<void> clearSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('search_history');
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  /// Debounce timer'ı iptal et
  void cancelSearch() {
    _searchDebounce?.cancel();
  }

  /// Dispose
  void dispose() {
    _searchDebounce?.cancel();
  }
}

/// Arama servisi hata sınıfı
class SearchServiceException implements Exception {
  final String message;
  SearchServiceException(this.message);
  
  @override
  String toString() => 'SearchServiceException: $message';
}
