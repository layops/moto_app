import 'dart:convert'; // utf8 ve base64Url için gerekli import
import 'package:flutter/material.dart';
import '../storage/local_storage.dart';

class TokenService {
  final LocalStorage _storage;

  TokenService(this._storage);

  Future<void> saveAuthData(String token, String username) async {
    await _storage.setString('auth_token', token);
    await _storage.setString('username', username);
  }

  Future<void> deleteAuthData() async {
    await _storage.remove('auth_token');
    await _storage.remove('username');
  }

  Future<bool> hasToken() async {
    return (await getToken()) != null;
  }

  Future<String?> getToken() async {
    return await _storage.getString('auth_token');
  }

  Future<Map<String, dynamic>?> getTokenData() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      // JWT token decode işlemi
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalizedPayload = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalizedPayload));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Token decode hatası: $e');
      return null;
    }
  }

  Future<String?> getUsernameFromToken() async {
    final tokenData = await getTokenData();
    return tokenData?['username']?.toString();
  }
}
