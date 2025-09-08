import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  late final SharedPreferences _prefs;
  
  // Memory cache için
  final Map<String, dynamic> _memoryCache = {};
  static const Duration _cacheExpiry = Duration(minutes: 10);
  final Map<String, DateTime> _cacheTimestamps = {};

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<bool> setBool(String key, bool value) async {
    _memoryCache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
    return await _prefs.setBool(key, value);
  }
  
  bool? getBool(String key) {
    // Memory cache kontrolü
    if (_isCacheValid(key) && _memoryCache.containsKey(key)) {
      return _memoryCache[key] as bool?;
    }
    
    final value = _prefs.getBool(key);
    if (value != null) {
      _memoryCache[key] = value;
      _cacheTimestamps[key] = DateTime.now();
    }
    return value;
  }

  Future<bool> setString(String key, String value) async {
    _memoryCache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
    return await _prefs.setString(key, value);
  }
  
  String? getString(String key) {
    // Memory cache kontrolü
    if (_isCacheValid(key) && _memoryCache.containsKey(key)) {
      return _memoryCache[key] as String?;
    }
    
    final value = _prefs.getString(key);
    if (value != null) {
      _memoryCache[key] = value;
      _cacheTimestamps[key] = DateTime.now();
    }
    return value;
  }

  Future<bool> remove(String key) async {
    _memoryCache.remove(key);
    _cacheTimestamps.remove(key);
    return await _prefs.remove(key);
  }

  // TOKEN
  Future<bool> setAuthToken(String token) async =>
      await setString('auth_token', token);
  String? getAuthToken() => getString('auth_token');
  Future<bool> removeAuthToken() async => await remove('auth_token');

  // KULLANICI
  Future<bool> setCurrentUsername(String username) async =>
      await setString('current_username', username);
  String? getCurrentUsername() => getString('current_username');
  Future<bool> removeCurrentUsername() async =>
      await remove('current_username');

  // REMEMBER ME
  Future<bool> setRememberMe(bool value) async =>
      await setBool('rememberMe', value);
  bool? getRememberMe() => getBool('rememberMe');

  Future<bool> setRememberedUsername(String username) async =>
      await setString('rememberedUsername', username);
  String? getRememberedUsername() => getString('rememberedUsername');
  Future<bool> clearRememberedUsername() async =>
      await remove('rememberedUsername');

  Future<void> clearAll() async {
    _memoryCache.clear();
    _cacheTimestamps.clear();
    await _prefs.clear();
  }
  
  Future<void> clearAuthData() async {
    await removeAuthToken();
    await removeCurrentUsername();
  }
  
  // Cache helper methods
  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }
  
  void clearMemoryCache() {
    _memoryCache.clear();
    _cacheTimestamps.clear();
  }

  static const String _profileDataKey = 'profile_data';

  Future<void> saveProfileData(Map<String, dynamic> profileData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileDataKey, json.encode(profileData));
    } catch (e) {
      print('Profil verileri kaydedilirken hata: $e');
    }
  }

  Future<Map<String, dynamic>?> getProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileDataString = prefs.getString(_profileDataKey);
      if (profileDataString != null) {
        return json.decode(profileDataString) as Map<String, dynamic>;
      }
    } catch (e) {
      print('Profil verileri okunurken hata: $e');
    }
    return null;
  }

  Future<void> clearProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileDataKey);
    } catch (e) {
      print('Profil verileri temizlenirken hata: $e');
    }
  }
}
