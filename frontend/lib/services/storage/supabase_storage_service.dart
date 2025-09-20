import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';

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
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last;
      final fileName = 'profile_${timestamp}.$extension';
      
      print('🔥 Profile file name: $fileName');
      
      final response = await Supabase.instance.client.storage
          .from(bucketToUse)
          .upload(fileName, imageFile);

      print('🔥 Profile upload response: $response');

      final publicUrl = Supabase.instance.client.storage
          .from(bucketToUse)
          .getPublicUrl(fileName);

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
      print('🔥 Supabase URL: ${Supabase.instance.client.supabaseUrl}');
      print('🔥 Supabase Key: ${Supabase.instance.client.supabaseKey.substring(0, 20)}...');
      
      // Basit bir test yap
      final response = await Supabase.instance.client.from('users').select('count').limit(1);
      print('🔥 Database connection test: SUCCESS');
    } catch (e) {
      print('🔥 Database connection test: FAILED - $e');
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
      
      // Bucket'ın var olup olmadığını kontrol et
      String bucketToUse = _coverBucket;
      try {
        final buckets = await Supabase.instance.client.storage.listBuckets();
        print('🔥 Available buckets: ${buckets.map((b) => b.name).toList()}');
        
        final coverBucketExists = buckets.any((bucket) => bucket.name == _coverBucket);
        if (!coverBucketExists) {
          print('🔥 WARNING: Cover bucket $_coverBucket does not exist!');
          
          // Bucket oluşturmayı dene
          try {
            print('🔥 Attempting to create bucket: $_coverBucket');
            await Supabase.instance.client.storage.createBucket(
              _coverBucket,
              BucketOptions(
                public: true,
                allowedMimeTypes: ['image/*'],
                fileSizeLimit: 5 * 1024 * 1024, // 5MB
              ),
            );
            print('🔥 Bucket created successfully: $_coverBucket');
            bucketToUse = _coverBucket;
          } catch (createError) {
            print('🔥 Failed to create bucket: $createError');
            
            // Alternatif bucket'ları dene
            final alternatives = ['moto-app-storage', 'profile_pictures', 'images', 'storage'];
            for (final altBucket in alternatives) {
              if (buckets.any((bucket) => bucket.name == altBucket)) {
                bucketToUse = altBucket;
                print('🔥 Using alternative bucket: $bucketToUse');
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
        }
      } catch (bucketError) {
        print('🔥 Bucket check error: $bucketError');
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last;
      final fileName = 'cover_${timestamp}.$extension';
      
      print('🔥 File name: $fileName');
      
      final response = await Supabase.instance.client.storage
          .from(bucketToUse)
          .upload(fileName, imageFile);

      print('🔥 Upload response: $response');

      final publicUrl = Supabase.instance.client.storage
          .from(bucketToUse)
          .getPublicUrl(fileName);

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
}
