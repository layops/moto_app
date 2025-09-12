import 'dart:convert';
import 'package:flutter/material.dart';
import '../storage/local_storage.dart';

class TokenService {
  final LocalStorage _storage;

  TokenService(this._storage);

  Future<void> saveAuthData(String token, String username, {String? refreshToken}) async {
    await _storage.setAuthToken(token);
    await _storage.setCurrentUsername(username);
    if (refreshToken != null) {
      await _storage.setString('refresh_token', refreshToken);
    }
  }

  Future<void> deleteAuthData() async {
    await _storage.removeAuthToken();
    await _storage.removeCurrentUsername();
    await _storage.remove('refresh_token');
  }

  Future<String?> getRefreshToken() async {
    return _storage.getString('refresh_token');
  }

  Future<bool> hasToken() async {
    return (await getToken()) != null;
  }

  Future<String?> getToken() async {
    return _storage.getAuthToken();
  }

  Future<Map<String, dynamic>?> getTokenData() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      String normalizedPayload = parts[1];
      final padding = 4 - (normalizedPayload.length % 4);
      if (padding != 4) {
        normalizedPayload += '=' * padding;
      }

      final decoded = utf8.decode(base64Url.decode(normalizedPayload));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getUsernameFromToken() async {
    try {
      final tokenData = await getTokenData();
      if (tokenData?['username'] != null) {
        return tokenData!['username']?.toString();
      }
      return await getCurrentUsername();
    } catch (e) {
      return await getCurrentUsername();
    }
  }

  Future<String?> getCurrentUsername() async {
    return _storage.getCurrentUsername();
  }

  Future<bool> isTokenExpired() async {
    final tokenData = await getTokenData();
    if (tokenData == null) return true;

    final exp = tokenData['exp'];
    if (exp == null) return true;

    final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    return DateTime.now()
        .isAfter(expiryTime.subtract(const Duration(minutes: 5)));
  }
}
