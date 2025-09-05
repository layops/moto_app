import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

/// Supabase Storage servisi
class SupabaseStorageService {
  static final SupabaseStorageService _instance = SupabaseStorageService._internal();
  factory SupabaseStorageService() => _instance;
  SupabaseStorageService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  /// Grup profil fotoğrafı yükle
  Future<String> uploadGroupProfilePicture(File imageFile) async {
    try {
      // Dosya uzantısını al
      final extension = path.extension(imageFile.path);
      
      // Benzersiz dosya adı oluştur
      final fileName = '${_uuid.v4()}$extension';
      
      // Dosyayı oku
      final bytes = await imageFile.readAsBytes();
      
      // Supabase Storage'a yükle
      final response = await _supabase.storage
          .from('groups_profile_pictures')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Public URL'i al
      final publicUrl = _supabase.storage
          .from('groups_profile_pictures')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      throw Exception('Profil fotoğrafı yüklenemedi: ${e.toString()}');
    }
  }

  /// Grup profil fotoğrafı güncelle
  Future<String> updateGroupProfilePicture(String oldFileName, File newImageFile) async {
    try {
      // Eski dosyayı sil
      if (oldFileName.isNotEmpty) {
        await deleteGroupProfilePicture(oldFileName);
      }
      
      // Yeni dosyayı yükle
      return await uploadGroupProfilePicture(newImageFile);
    } catch (e) {
      throw Exception('Profil fotoğrafı güncellenemedi: ${e.toString()}');
    }
  }

  /// Grup profil fotoğrafı sil
  Future<void> deleteGroupProfilePicture(String fileName) async {
    try {
      // URL'den dosya adını çıkar
      final filePath = _extractFilePathFromUrl(fileName);
      
      if (filePath.isNotEmpty) {
        await _supabase.storage
            .from('groups_profile_pictures')
            .remove([filePath]);
      }
    } catch (e) {
      // Silme hatası kritik değil, sadece log'la
      print('Dosya silinemedi: $e');
    }
  }

  /// URL'den dosya yolunu çıkar
  String _extractFilePathFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      
      // Supabase storage URL formatı: /storage/v1/object/public/bucket_name/file_name
      if (pathSegments.length >= 4 && pathSegments[2] == 'groups_profile_pictures') {
        return pathSegments.sublist(3).join('/');
      }
      
      return '';
    } catch (e) {
      return '';
    }
  }

  /// Dosya boyutunu kontrol et (max 5MB)
  bool validateFileSize(File file) {
    const maxSizeInBytes = 5 * 1024 * 1024; // 5MB
    return file.lengthSync() <= maxSizeInBytes;
  }

  /// Dosya tipini kontrol et
  bool validateFileType(File file) {
    final extension = path.extension(file.path).toLowerCase();
    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
    return allowedExtensions.contains(extension);
  }

  /// Dosya validasyonu
  String? validateImageFile(File file) {
    if (!validateFileType(file)) {
      return 'Sadece JPG, PNG ve WebP formatları desteklenir';
    }
    
    if (!validateFileSize(file)) {
      return 'Dosya boyutu 5MB\'dan küçük olmalıdır';
    }
    
    return null;
  }

  /// Resmi yeniden boyutlandır (opsiyonel)
  Future<Uint8List> resizeImage(File imageFile, {int maxWidth = 800, int maxHeight = 800}) async {
    // Bu fonksiyon image paketi ile implement edilebilir
    // Şimdilik orijinal dosyayı döndürüyoruz
    return await imageFile.readAsBytes();
  }
}
