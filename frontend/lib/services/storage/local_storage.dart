import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  late final SharedPreferences _prefs;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      throw Exception('SharedPreferences başlatılamadı: $e');
    }
  }

  // GENEL METODLAR
  Future<bool> setBool(String key, bool value) async {
    try {
      return await _prefs.setBool(key, value);
    } catch (e) {
      throw Exception('Bool kaydedilemedi: $e');
    }
  }

  bool? getBool(String key) {
    try {
      return _prefs.getBool(key);
    } catch (e) {
      throw Exception('Bool okunamadı: $e');
    }
  }

  Future<bool> setString(String key, String value) async {
    try {
      return await _prefs.setString(key, value);
    } catch (e) {
      throw Exception('String kaydedilemedi: $e');
    }
  }

  String? getString(String key) {
    try {
      return _prefs.getString(key);
    } catch (e) {
      throw Exception('String okunamadı: $e');
    }
  }

  Future<bool> remove(String key) async {
    try {
      return await _prefs.remove(key);
    } catch (e) {
      throw Exception('Veri silinemedi: $e');
    }
  }

  bool containsKey(String key) {
    try {
      return _prefs.containsKey(key);
    } catch (e) {
      throw Exception('Key kontrol edilemedi: $e');
    }
  }

  // TOKEN İŞLEMLERİ
  Future<bool> setAuthToken(String token) async {
    return await setString('authToken', token);
  }

  String? getAuthToken() {
    return getString('authToken');
  }

  Future<bool> removeAuthToken() async {
    return await remove('authToken');
  }

  // KULLANICI BİLGİLERİ
  Future<bool> setCurrentUsername(String username) async {
    return await setString('currentUsername', username);
  }

  String? getCurrentUsername() {
    return getString('currentUsername');
  }

  Future<bool> removeCurrentUsername() async {
    return await remove('currentUsername');
  }

  // REMEMBER ME
  Future<bool> setRememberMe(bool value) async {
    return await setBool('rememberMe', value);
  }

  bool? getRememberMe() {
    return getBool('rememberMe');
  }

  Future<bool> setRememberedUsername(String username) async {
    return await setString('rememberedUsername', username);
  }

  String? getRememberedUsername() {
    return getString('rememberedUsername');
  }

  Future<bool> clearRememberedUsername() async {
    return await remove('rememberedUsername');
  }

  // TEMİZLEME METODLARI
  Future<void> clearAll() async {
    try {
      await _prefs.clear();
    } catch (e) {
      throw Exception('Tüm veriler temizlenemedi: $e');
    }
  }

  Future<void> clearAuthData() async {
    try {
      await removeAuthToken();
      await removeCurrentUsername();
    } catch (e) {
      throw Exception('Auth verileri temizlenemedi: $e');
    }
  }
}
