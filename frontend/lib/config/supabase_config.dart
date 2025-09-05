/// Supabase konfigürasyon dosyası
class SupabaseConfig {
  // Supabase proje URL'inizi buraya ekleyin
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  
  // Supabase anon key'inizi buraya ekleyin
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
  // Storage bucket isimleri
  static const String groupsProfilePicturesBucket = 'groups_profile_pictures';
  
  // Dosya boyutu limitleri
  static const int maxFileSizeInBytes = 5 * 1024 * 1024; // 5MB
  
  // Desteklenen dosya formatları
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
}
