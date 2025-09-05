/// Supabase konfigürasyon dosyası
class SupabaseConfig {
  // Supabase proje URL'inizi buraya ekleyin
  static const String supabaseUrl = 'https://mosiqkyyribzlvdvedet.supabase.co';
  
  // Supabase anon key'inizi buraya ekleyin
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vc2lxa3l5cmliemx2ZHZlZGV0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY2NDM0NzUsImV4cCI6MjA3MjIxOTQ3NX0.x3_gZOXMbxNd_KAj_UxRif04hwpZ46aARB_ocZZIIbM';
  
  // Storage bucket isimleri
  static const String groupsProfilePicturesBucket = 'groups_profile_pictures';
  
  // Dosya boyutu limitleri
  static const int maxFileSizeInBytes = 5 * 1024 * 1024; // 5MB
  
  // Desteklenen dosya formatları
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
}
