#!/usr/bin/env python
"""
Supabase Storage Test Script
Profil fotoğrafı yükleme servisini test eder
"""
import os
import sys
import django

# Django setup
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core_api.settings')
django.setup()

from users.services.supabase_storage_service import SupabaseStorageService
from django.conf import settings

def test_supabase_storage():
    """Supabase Storage servisini test eder"""
    print("🔍 Supabase Storage Test Başlatılıyor...")
    print(f"SUPABASE_URL: {getattr(settings, 'SUPABASE_URL', 'YOK')}")
    print(f"SUPABASE_SERVICE_KEY: {'VAR' if getattr(settings, 'SUPABASE_SERVICE_KEY', None) else 'YOK'}")
    print(f"SUPABASE_BUCKET: {getattr(settings, 'SUPABASE_BUCKET', 'YOK')}")
    print(f"SUPABASE_COVER_BUCKET: {getattr(settings, 'SUPABASE_COVER_BUCKET', 'YOK')}")
    
    # Storage servisini başlat
    storage_service = SupabaseStorageService()
    
    if storage_service.is_available:
        print("✅ Supabase Storage servisi başarıyla başlatıldı!")
        print(f"Profile Bucket: {storage_service.profile_bucket}")
        print(f"Cover Bucket: {storage_service.cover_bucket}")
        
        # Bucket'ları kontrol et
        try:
            # Profile bucket'ı kontrol et
            profile_files = storage_service.client.storage.from_(storage_service.profile_bucket).list()
            print(f"📁 Profile bucket'ında {len(profile_files)} dosya var")
            
            # Cover bucket'ı kontrol et
            cover_files = storage_service.client.storage.from_(storage_service.cover_bucket).list()
            print(f"📁 Cover bucket'ında {len(cover_files)} dosya var")
            
        except Exception as e:
            print(f"⚠️ Bucket kontrol hatası: {e}")
            print("💡 Bucket'ları Supabase dashboard'unda oluşturmayı unutmayın!")
            
    else:
        print("❌ Supabase Storage servisi başlatılamadı!")
        print("🔧 Environment variables'ları kontrol edin:")
        print("   - SUPABASE_URL")
        print("   - SUPABASE_SERVICE_KEY")
        print("   - SUPABASE_BUCKET")
        print("   - SUPABASE_COVER_BUCKET")

if __name__ == "__main__":
    test_supabase_storage()
