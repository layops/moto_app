from django.core.management.base import BaseCommand
from users.services.supabase_storage_service import SupabaseStorageService
import os

class Command(BaseCommand):
    help = 'Supabase Storage bucket\'larını oluşturur'

    def handle(self, *args, **options):
        self.stdout.write("=== Supabase Bucket Oluşturma ===")
        
        # Environment variables'ları set et
        os.environ['SUPABASE_URL'] = 'https://mosiqkyyribzlvdvedet.supabase.co'
        os.environ['SUPABASE_SERVICE_KEY'] = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vc2lxa3l5cmliemx2ZHZlZGV0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NjY0MzQ3NSwiZXhwIjoyMDcyMjE5NDc1fQ.oxEaRtYZF74vTIttVCaBhmeNaEyUAEdQHVbSWYOPTUA'
        
        # 1. Servis oluştur
        self.stdout.write("\n1. SupabaseStorageService oluşturuluyor...")
        storage_service = SupabaseStorageService()
        
        if not storage_service.is_available:
            self.stdout.write(self.style.ERROR("❌ Supabase Storage servisi kullanılamıyor"))
            return
        
        self.stdout.write("✅ Supabase Storage servisi hazır")
        
        # 2. Mevcut bucket'ları kontrol et
        self.stdout.write("\n2. Mevcut bucket'lar kontrol ediliyor...")
        try:
            buckets = storage_service.client.storage.list_buckets()
            existing_buckets = [bucket.name for bucket in buckets]
            self.stdout.write(f"📁 Mevcut bucket'lar: {existing_buckets}")
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"❌ Bucket listesi alınamadı: {e}"))
            return
        
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
        
        self.stdout.write("\n3. Bucket'lar oluşturuluyor...")
        
        for bucket_config in required_buckets:
            bucket_name = bucket_config['name']
            
            if bucket_name in existing_buckets:
                self.stdout.write(f"✅ {bucket_name} bucket zaten mevcut")
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
                    self.stdout.write(f"✅ {bucket_name} bucket oluşturuldu")
                else:
                    self.stdout.write(self.style.ERROR(f"❌ {bucket_name} bucket oluşturulamadı"))
                    
            except Exception as e:
                self.stdout.write(self.style.ERROR(f"❌ {bucket_name} bucket oluşturma hatası: {e}"))
        
        # 4. Son kontrol
        self.stdout.write("\n4. Son kontrol yapılıyor...")
        try:
            buckets = storage_service.client.storage.list_buckets()
            final_buckets = [bucket.name for bucket in buckets]
            self.stdout.write(f"📁 Final bucket'lar: {final_buckets}")
            
            for bucket_config in required_buckets:
                bucket_name = bucket_config['name']
                if bucket_name in final_buckets:
                    self.stdout.write(f"✅ {bucket_name} bucket hazır")
                else:
                    self.stdout.write(self.style.ERROR(f"❌ {bucket_name} bucket bulunamadı"))
                    
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"❌ Son kontrol hatası: {e}"))
        
        self.stdout.write("\n=== Bucket Oluşturma Tamamlandı ===")
