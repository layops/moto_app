"""
Django Management Command: test_supabase_storage
Supabase storage bağlantısını test eder
"""

from django.core.management.base import BaseCommand
from django.conf import settings
import os
from users.services.supabase_storage_service import SupabaseStorageService

class Command(BaseCommand):
    help = 'Supabase storage bağlantısını test eder'

    def handle(self, *args, **options):
        self.stdout.write(
            self.style.SUCCESS('🔍 Supabase Storage Test Başlıyor...')
        )
        self.stdout.write('=' * 60)
        
        # Environment variables kontrolü
        self.stdout.write('📋 Environment Variables:')
        self.stdout.write(f"   SUPABASE_URL: {'VAR' if os.getenv('SUPABASE_URL') else 'YOK'}")
        self.stdout.write(f"   SUPABASE_ANON_KEY: {'VAR' if os.getenv('SUPABASE_ANON_KEY') else 'YOK'}")
        self.stdout.write(f"   SUPABASE_SERVICE_ROLE_KEY: {'VAR' if os.getenv('SUPABASE_SERVICE_ROLE_KEY') else 'YOK'}")
        self.stdout.write('')
        
        # Settings kontrolü
        self.stdout.write('⚙️ Django Settings:')
        self.stdout.write(f"   SUPABASE_URL: {'VAR' if getattr(settings, 'SUPABASE_URL', None) else 'YOK'}")
        self.stdout.write(f"   SUPABASE_ANON_KEY: {'VAR' if getattr(settings, 'SUPABASE_ANON_KEY', None) else 'YOK'}")
        self.stdout.write(f"   SUPABASE_SERVICE_ROLE_KEY: {'VAR' if getattr(settings, 'SUPABASE_SERVICE_ROLE_KEY', None) else 'YOK'}")
        self.stdout.write('')
        
        # SupabaseStorageService test
        self.stdout.write('🚀 SupabaseStorageService Test:')
        storage_service = SupabaseStorageService()
        
        if storage_service.is_available:
            self.stdout.write(self.style.SUCCESS('✅ SupabaseStorageService başarıyla başlatıldı'))
            
            # Bucket test
            bucket_test = storage_service.test_connection()
            if bucket_test['success']:
                self.stdout.write(self.style.SUCCESS('✅ Bucket bağlantısı başarılı'))
                self.stdout.write(f"   Bucket'lar: {bucket_test['buckets']}")
            else:
                self.stdout.write(self.style.ERROR(f'❌ Bucket bağlantısı başarısız: {bucket_test["error"]}'))
        else:
            self.stdout.write(self.style.ERROR('❌ SupabaseStorageService başlatılamadı'))
        
        self.stdout.write('')
        self.stdout.write(
            self.style.SUCCESS('🎉 Test tamamlandı!')
        )
