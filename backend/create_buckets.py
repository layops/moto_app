#!/usr/bin/env python
"""
Supabase Bucket Oluşturma Script
"""
import os
import sys
import django

# Django setup
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core_api.settings')
django.setup()

from users.services.supabase_storage_service import SupabaseStorageService

def create_buckets():
    print("=== Supabase Bucket Oluşturma ===")
    
    # Environment variables'ları set et
    os.environ['SUPABASE_URL'] = 'https://mosiqkyyribzlvdvedet.supabase.co'
    os.environ['SUPABASE_SERVICE_KEY'] = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vc2lxa3l5cmliemx2ZHZlZGV0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NjY0MzQ3NSwiZXhwIjoyMDcyMjE5NDc1fQ.oxEaRtYZF74vTIttVCaBhmeNaEyUAEdQHVbSWYOPTUA'
    
    # 1. Servis oluştur
    print("\n1. SupabaseStorageService oluşturuluyor...")
    storage_service = SupabaseStorageService()
    
    if not storage_service.is_available:
        print("❌ Supabase Storage servisi kullanılamıyor")
        return False
    
    print("✅ Supabase Storage servisi hazır")
    
    # 2. Mevcut bucket'ları kontrol et
    print("\n2. Mevcut bucket'lar kontrol ediliyor...")
    try:
        buckets = storage_service.client.storage.list_buckets()
        existing_buckets = [bucket.name for bucket in buckets]
        print(f"📁 Mevcut bucket'lar: {existing_buckets}")
    except Exception as e:
        print(f"❌ Bucket listesi alınamadı: {e}")
        return False
    
    # 3. Gerekli bucket'ları oluştur
    required_buckets = [
        {
            'name': 'profile-pictures',
            'public': True,
            'description': 'Kullanıcı profil fotoğrafları'
        },
        {
            'name': 'event-pictures', 
            'public': True,
            'description': 'Event kapak fotoğrafları'
        }
    ]
    
    print("\n3. Bucket'lar oluşturuluyor...")
    
    for bucket_config in required_buckets:
        bucket_name = bucket_config['name']
        
        if bucket_name in existing_buckets:
            print(f"✅ {bucket_name} bucket zaten mevcut")
            continue
        
        try:
            # Bucket oluştur
            result = storage_service.client.storage.create_bucket(
                bucket_name,
                options={
                    'public': bucket_config['public']
                }
            )
            
            if result:
                print(f"✅ {bucket_name} bucket oluşturuldu")
            else:
                print(f"❌ {bucket_name} bucket oluşturulamadı")
                
        except Exception as e:
            print(f"❌ {bucket_name} bucket oluşturma hatası: {e}")
    
    # 4. Son kontrol
    print("\n4. Son kontrol yapılıyor...")
    try:
        buckets = storage_service.client.storage.list_buckets()
        final_buckets = [bucket.name for bucket in buckets]
        print(f"📁 Final bucket'lar: {final_buckets}")
        
        for bucket_config in required_buckets:
            bucket_name = bucket_config['name']
            if bucket_name in final_buckets:
                print(f"✅ {bucket_name} bucket hazır")
            else:
                print(f"❌ {bucket_name} bucket bulunamadı")
                
    except Exception as e:
        print(f"❌ Son kontrol hatası: {e}")
        return False
    
    print("\n=== Bucket Oluşturma Tamamlandı ===")
    return True

if __name__ == "__main__":
    success = create_buckets()
    sys.exit(0 if success else 1)
