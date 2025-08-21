import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<bool> setBool(String key, bool value) async =>
      await _prefs.setBool(key, value);
  bool? getBool(String key) => _prefs.getBool(key);

  Future<bool> setString(String key, String value) async =>
      await _prefs.setString(key, value);
  String? getString(String key) => _prefs.getString(key);

  Future<bool> remove(String key) async => await _prefs.remove(key);

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

  Future<void> clearAll() async => await _prefs.clear();
  Future<void> clearAuthData() async {
    await removeAuthToken();
    await removeCurrentUsername();
  }
}
