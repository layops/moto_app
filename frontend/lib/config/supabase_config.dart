/// Supabase konfigürasyon dosyası
class SupabaseConfig {
  // Supabase proje URL'inizi buraya ekleyin
  static const String supabaseUrl = 'https://mosiqkyyribzlvdvedet.supabase.co';
  
  // Supabase anon key'inizi buraya ekleyin
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vc2lxa3l5cmliemx2ZHZlZGV0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY2NDM0NzUsImV4cCI6MjA3MjIxOTQ3NX0.x3_gZOXMbxNd_KAj_UxRif04hwpZ46aARB_ocZZIIbM';
  
  // Storage bucket isimleri - Backend ile uyumlu
  static const String profilePicturesBucket = 'profile_pictures';
  static const String eventsPicturesBucket = 'events_pictures';
  static const String coverPicturesBucket = 'cover_pictures';
  static const String groupsProfilePicturesBucket = 'groups_profile_pictures';
  static const String groupPostsImagesBucket = 'group_posts_images';
  static const String bikesImagesBucket = 'bikes_images';
  
  // Dosya boyutu limitleri
  static const int maxFileSizeInBytes = 5 * 1024 * 1024; // 5MB
  
  // Desteklenen dosya formatları
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
  
  // Supabase Storage ayarları
  static const Duration uploadTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
}
