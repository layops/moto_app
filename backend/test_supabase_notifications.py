#!/usr/bin/env python
"""
Supabase Notifications Test Script
"""
import os
import sys
import django

# Django setup
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core_api.settings')
django.setup()

from django.contrib.auth import get_user_model
from notifications.utils import send_notification_with_preferences
from notifications.supabase_client import get_supabase_client

User = get_user_model()

def test_supabase_connection():
    """Supabase bağlantısını test et"""
    print("🔍 Supabase bağlantısı test ediliyor...")
    try:
        client = get_supabase_client()
        print("✅ Supabase client başarıyla oluşturuldu")
        return True
    except Exception as e:
        print(f"❌ Supabase bağlantı hatası: {e}")
        return False

def test_notification_system():
    """Bildirim sistemini test et"""
    print("\n🔔 Bildirim sistemi test ediliyor...")
    
    try:
        # Test kullanıcısı al veya oluştur
        test_user, created = User.objects.get_or_create(
            username='test_user',
            defaults={
                'email': 'test@example.com',
                'first_name': 'Test',
                'last_name': 'User'
            }
        )
        
        if created:
            print(f"✅ Test kullanıcısı oluşturuldu: {test_user.username}")
        else:
            print(f"✅ Test kullanıcısı bulundu: {test_user.username}")
        
        # Test bildirimi gönder
        notification = send_notification_with_preferences(
            recipient_user=test_user,
            message="Bu bir test bildirimidir! 🚀",
            notification_type="test",
            title="Supabase Test Bildirimi"
        )
        
        if notification:
            print(f"✅ Test bildirimi başarıyla gönderildi: ID={notification.id}")
            return True
        else:
            print("❌ Test bildirimi gönderilemedi")
            return False
            
    except Exception as e:
        print(f"❌ Bildirim test hatası: {e}")
        return False

def main():
    """Ana test fonksiyonu"""
    print("🚀 Supabase Notifications Test Başlatılıyor...\n")
    
    # Supabase bağlantı testi
    if not test_supabase_connection():
        print("\n❌ Supabase bağlantısı başarısız. Test durduruluyor.")
        return
    
    # Bildirim sistemi testi
    if test_notification_system():
        print("\n🎉 Tüm testler başarılı! Supabase bildirim sistemi çalışıyor.")
    else:
        print("\n❌ Bildirim sistemi testi başarısız.")

if __name__ == "__main__":
    main()
