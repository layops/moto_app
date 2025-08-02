import 'dart:convert';

Map<String, dynamic> parseJwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length != 3) {
    throw Exception('Geçersiz JWT token');
  }

  final payload = parts[1];

  // Base64 string'i standart hale getir
  String normalized = base64.normalize(payload);
  final decodedBytes = base64Url.decode(normalized);
  final decodedString = utf8.decode(decodedBytes);
  return json.decode(decodedString) as Map<String, dynamic>;
}
