// Chat sistemi için ek özellikler
class ChatEnhancements {
  
  /// Mesaj okundu bilgisi gönder
  static Future<void> markMessageAsRead(int messageId) async {
    // TODO: Backend API'ye mesaj okundu bilgisi gönder
  }
  
  /// Online/offline durumu kontrol et
  static Future<bool> checkUserOnlineStatus(int userId) async {
    // TODO: Backend API'den kullanıcı durumu al
    return false;
  }
  
  /// Mesaj silme (sadece kendi mesajları)
  static Future<void> deleteMessage(int messageId) async {
    // TODO: Backend API'ye mesaj silme isteği gönder
  }
  
  /// Mesaj düzenleme
  static Future<void> editMessage(int messageId, String newContent) async {
    // TODO: Backend API'ye mesaj düzenleme isteği gönder
  }
  
  /// Mesaj tepkisi (emoji)
  static Future<void> addReaction(int messageId, String emoji) async {
    // TODO: Backend API'ye tepki ekleme isteği gönder
  }
}
