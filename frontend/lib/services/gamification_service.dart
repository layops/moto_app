import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'auth/token_service.dart';

class GamificationService {
  static const String _baseUrl = Config.apiBaseUrl;
  final TokenService _tokenService;

  GamificationService(this._tokenService);

  Future<List<dynamic>> getLeaderboard() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/gamification/leaderboard/users/'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<dynamic>.from(data);
      } else {
        throw Exception('Liderlik tablosu alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Liderlik tablosu yüklenirken hata: $e');
    }
  }

  Future<List<dynamic>> getUserAchievements() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/gamification/achievements/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<dynamic>.from(data);
      } else {
        throw Exception('Başarımlar alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Başarımlar yüklenirken hata: $e');
    }
  }

  Future<Map<String, dynamic>> getUserScoreSummary() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/gamification/score-summary/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Puan özeti alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Puan özeti yüklenirken hata: $e');
    }
  }

  Future<void> updateAchievementProgress({
    required String achievementType,
    required int progressValue,
  }) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/gamification/achievements/update-progress/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'achievement_type': achievementType,
          'progress_value': progressValue,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Başarım ilerlemesi güncellenemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Başarım ilerlemesi güncellenirken hata: $e');
    }
  }

  Future<String> _getToken() async {
    final token = await _tokenService.getToken();
    if (token == null) {
      throw Exception('Token bulunamadı. Lütfen giriş yapın.');
    }
    return token;
  }
}
