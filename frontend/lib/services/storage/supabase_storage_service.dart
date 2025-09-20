import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';
import '../service_locator.dart';

class UploadResult {
  final bool success;
  final String? url;
  final String? error;

  UploadResult({
    required this.success,
    this.url,
    this.error,
  });
}

class SupabaseStorageService {
  // Backend ile uyumlu bucket isimleri kullan
  static const String _profileBucket = SupabaseConfig.profilePicturesBucket;
  static const String _coverBucket = SupabaseConfig.coverPicturesBucket;
  static const String _eventsBucket = SupabaseConfig.eventsPicturesBucket;
  static const String _groupsBucket = SupabaseConfig.groupsProfilePicturesBucket;
  static const String _postsBucket = SupabaseConfig.groupPostsImagesBucket;
  static const String _bikesBucket = SupabaseConfig.bikesImagesBucket;

  /// Profil fotoğrafı yükleme
  Future<UploadResult> uploadProfilePicture(File imageFile) async {
    try {
      print('🔥 SUPABASE PROFILE UPLOAD START');
      
      // Bucket'ın var olup olmadığını kontrol et
      String bucketToUse = _profileBucket;
      try {
        final buckets = await Supabase.instance.client.storage.listBuckets();
        print('🔥 Available buckets for profile: ${buckets.map((b) => b.name).toList()}');
        
        final profileBucketExists = buckets.any((bucket) => bucket.name == _profileBucket);
        if (!profileBucketExists) {
          print('🔥 WARNING: Profile bucket $_profileBucket does not exist!');
          
          // Alternatif bucket'ları dene
          final alternatives = ['moto-app-storage', 'cover_pictures', 'images', 'storage'];
          for (final altBucket in alternatives) {
            if (buckets.any((bucket) => bucket.name == altBucket)) {
              bucketToUse = altBucket;
              print('🔥 Using alternative bucket for profile: $bucketToUse');
              break;
            }
          }
          
          // Hiç bucket yoksa hata döndür
          if (!buckets.any((bucket) => bucket.name == bucketToUse)) {
            return UploadResult(
              success: false,
              error: 'Hiçbir storage bucket bulunamadı. Lütfen yönetici ile iletişime geçin.',
            );
          }
        }
      } catch (bucketError) {
        print('🔥 Profile bucket check error: $bucketError');
      }
      
      // Kullanıcı ID'sini al
      final userId = await _getCurrentUserId();
      if (userId == null) {
        throw Exception('Kullanıcı ID bulunamadı');
      }
      
      // Eski profil fotoğrafını sil
      await _deleteOldProfilePicture(userId, bucketToUse);
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last;
      final fileName = 'profile_${timestamp}.$extension';
      final filePath = 'users/$userId/$fileName';
      
      print('🔥 Profile file path: $filePath');
      print('🔥 User ID: $userId');
      
      final response = await Supabase.instance.client.storage
          .from(bucketToUse)
          .upload(filePath, imageFile);

      print('🔥 Profile upload response: $response');

      final publicUrl = Supabase.instance.client.storage
          .from(bucketToUse)
          .getPublicUrl(filePath);

      print('🔥 Profile public URL: $publicUrl');

      return UploadResult(
        success: true,
        url: publicUrl,
      );
    } catch (e) {
      print('🔥 SUPABASE PROFILE UPLOAD ERROR: $e');
      return UploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }


  /// Supabase bağlantısını test et
  Future<void> testSupabaseConnection() async {
    try {
      print('🔥 TESTING SUPABASE CONNECTION...');
      print('🔥 Supabase URL: ${SupabaseConfig.supabaseUrl}');
      print('🔥 Supabase Key: ${SupabaseConfig.supabaseAnonKey.substring(0, 20)}...');
      
      // Storage bucket'larını test et
      try {
        final buckets = await Supabase.instance.client.storage.listBuckets();
        print('🔥 Storage buckets test: SUCCESS');
        print('🔥 Available buckets: ${buckets.map((b) => b.name).toList()}');
      } catch (storageError) {
        print('🔥 Storage buckets test: FAILED - $storageError');
      }
      
      // Basit bir test yap (users tablosu yerine auth test)
      try {
        final user = Supabase.instance.client.auth.currentUser;
        print('🔥 Auth test: SUCCESS - User: ${user?.email ?? "Anonymous"}');
      } catch (authError) {
        print('🔥 Auth test: FAILED - $authError');
      }
    } catch (e) {
      print('🔥 General connection test: FAILED - $e');
    }
  }

  /// Kapak fotoğrafı yükleme
  Future<UploadResult> uploadCoverPicture(File imageFile) async {
    try {
      print('🔥 SUPABASE COVER UPLOAD START');
      print('🔥 Bucket: $_coverBucket');
      print('🔥 File path: ${imageFile.path}');
      print('🔥 File size: ${await imageFile.length()} bytes');
      
      // Supabase bağlantısını test et
      await testSupabaseConnection();
      
      // Hardcoded bucket kullan (RLS sorunu nedeniyle)
      String bucketToUse = 'cover_pictures'; // Supabase'de mevcut bucket
      print('🔥 Using hardcoded bucket: $bucketToUse');
      
      // Kullanıcı ID'sini al
      final userId = await _getCurrentUserId();
      if (userId == null) {
        throw Exception('Kullanıcı ID bulunamadı');
      }
      
      // Eski kapak fotoğrafını sil
      await _deleteOldCoverPicture(userId, bucketToUse);
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last;
      final fileName = 'cover_${timestamp}.$extension';
      final filePath = 'users/$userId/$fileName';
      
      print('🔥 File path: $filePath');
      print('🔥 User ID: $userId');
      
      print('🔥 Attempting upload to bucket: $bucketToUse');
      
      final response = await Supabase.instance.client.storage
          .from(bucketToUse)
          .upload(filePath, imageFile);

      print('🔥 Upload response: $response');

      final publicUrl = Supabase.instance.client.storage
          .from(bucketToUse)
          .getPublicUrl(filePath);

      print('🔥 Public URL: $publicUrl');

      return UploadResult(
        success: true,
        url: publicUrl,
      );
    } catch (e) {
      print('🔥 SUPABASE COVER UPLOAD ERROR: $e');
      return UploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Post resmi yükleme
  Future<UploadResult> uploadPostImage(File imageFile) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last;
      final fileName = 'post_${timestamp}.$extension';
      
      final response = await Supabase.instance.client.storage
          .from(_postsBucket)
          .upload(fileName, imageFile);

      final publicUrl = Supabase.instance.client.storage
          .from(_postsBucket)
          .getPublicUrl(fileName);

      return UploadResult(
        success: true,
        url: publicUrl,
      );
    } catch (e) {
      return UploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Etkinlik resmi yükleme
  Future<UploadResult> uploadEventPicture(File imageFile) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last;
      final fileName = 'event_${timestamp}.$extension';
      
      final response = await Supabase.instance.client.storage
          .from(_eventsBucket)
          .upload(fileName, imageFile);

      final publicUrl = Supabase.instance.client.storage
          .from(_eventsBucket)
          .getPublicUrl(fileName);

      return UploadResult(
        success: true,
        url: publicUrl,
      );
    } catch (e) {
      return UploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Grup resmi yükleme
  Future<UploadResult> uploadGroupPicture(File imageFile) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last;
      final fileName = 'group_${timestamp}.$extension';
      
      final response = await Supabase.instance.client.storage
          .from(_groupsBucket)
          .upload(fileName, imageFile);

      final publicUrl = Supabase.instance.client.storage
          .from(_groupsBucket)
          .getPublicUrl(fileName);

      return UploadResult(
        success: true,
        url: publicUrl,
      );
    } catch (e) {
      return UploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Dosya silme
  Future<bool> deleteFile(String fileName, String bucketType) async {
    try {
      String bucketName;
      switch (bucketType) {
        case 'profile':
          bucketName = _profileBucket;
          break;
        case 'cover':
          bucketName = _coverBucket;
          break;
        case 'events':
          bucketName = _eventsBucket;
          break;
        case 'groups':
          bucketName = _groupsBucket;
          break;
        case 'posts':
          bucketName = _postsBucket;
          break;
        case 'bikes':
          bucketName = _bikesBucket;
          break;
        default:
          return false;
      }
      
      await Supabase.instance.client.storage
          .from(bucketName)
          .remove([fileName]);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Public URL alma
  String getPublicUrl(String fileName, String bucketType) {
    String bucketName;
    switch (bucketType) {
      case 'profile':
        bucketName = _profileBucket;
        break;
      case 'cover':
        bucketName = _coverBucket;
        break;
      case 'events':
        bucketName = _eventsBucket;
        break;
      case 'groups':
        bucketName = _groupsBucket;
        break;
      case 'posts':
        bucketName = _postsBucket;
        break;
      case 'bikes':
        bucketName = _bikesBucket;
        break;
      default:
        bucketName = _profileBucket;
    }
    
    return Supabase.instance.client.storage
        .from(bucketName)
        .getPublicUrl(fileName);
  }

  /// Mevcut kullanıcı ID'sini al
  Future<String?> _getCurrentUserId() async {
    try {
      // Önce Supabase auth'dan al
      final supabaseUser = Supabase.instance.client.auth.currentUser;
      if (supabaseUser?.id != null) {
        return supabaseUser!.id;
      }
      
      // Supabase'den alamazsak backend'den al
      final username = await ServiceLocator.user.getCurrentUsername();
      if (username != null) {
        // Backend'den kullanıcı ID'sini al
        final response = await ServiceLocator.api.get('users/$username/profile/');
        if (response.statusCode == 200 && response.data != null) {
          final userData = response.data;
          return userData['id']?.toString();
        }
      }
      
      return null;
    } catch (e) {
      print('🔥 User ID alma hatası: $e');
      return null;
    }
  }

  /// Eski profil fotoğrafını sil
  Future<void> _deleteOldProfilePicture(String userId, String bucket) async {
    try {
      // Kullanıcının profil fotoğrafı klasöründeki tüm dosyaları listele
      final files = await Supabase.instance.client.storage
          .from(bucket)
          .list(path: 'users/$userId/');
      
      // Profil fotoğraflarını bul ve sil
      for (final file in files) {
        if (file.name.startsWith('profile_')) {
          try {
            await Supabase.instance.client.storage
                .from(bucket)
                .remove(['users/$userId/${file.name}']);
            print('🔥 Eski profil fotoğrafı silindi: ${file.name}');
          } catch (e) {
            print('🔥 Profil fotoğrafı silme hatası: $e');
          }
        }
      }
    } catch (e) {
      print('🔥 Eski profil fotoğrafı listeleme hatası: $e');
    }
  }

  /// Eski kapak fotoğrafını sil
  Future<void> _deleteOldCoverPicture(String userId, String bucket) async {
    try {
      // Kullanıcının kapak fotoğrafı klasöründeki tüm dosyaları listele
      final files = await Supabase.instance.client.storage
          .from(bucket)
          .list(path: 'users/$userId/');
      
      // Kapak fotoğraflarını bul ve sil
      for (final file in files) {
        if (file.name.startsWith('cover_')) {
          try {
            await Supabase.instance.client.storage
                .from(bucket)
                .remove(['users/$userId/${file.name}']);
            print('🔥 Eski kapak fotoğrafı silindi: ${file.name}');
          } catch (e) {
            print('🔥 Kapak fotoğrafı silme hatası: $e');
          }
        }
      }
    } catch (e) {
      print('🔥 Eski kapak fotoğrafı listeleme hatası: $e');
    }
  }
}
