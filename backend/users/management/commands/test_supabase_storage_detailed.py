"""
Django Management Command: test_supabase_storage_detailed
Supabase storage bağlantısını detaylı test eder
"""

from django.core.management.base import BaseCommand
from django.conf import settings
import os
import logging

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = 'Supabase storage bağlantısını detaylı test eder'

    def add_arguments(self, parser):
        parser.add_argument(
            '--test-upload',
            action='store_true',
            help='Test dosya upload işlemi yap'
        )

    def handle(self, *args, **options):
        self.stdout.write(
            self.style.SUCCESS('🔍 Detaylı Supabase Storage Test Başlıyor...')
        )
        self.stdout.write('=' * 60)
        
        # 1. Environment Variables kontrolü
        self.stdout.write('📋 1. Environment Variables:')
        env_vars = ['SUPABASE_URL', 'SUPABASE_ANON_KEY', 'SUPABASE_SERVICE_ROLE_KEY']
        for var in env_vars:
            value = os.getenv(var)
            status = '✅ VAR' if value else '❌ YOK'
            self.stdout.write(f"   {var}: {status}")
            if value and var != 'SUPABASE_SERVICE_ROLE_KEY':  # Key'i gösterme
                self.stdout.write(f"      Value: {value[:50]}...")
        self.stdout.write('')
        
        # 2. Django Settings kontrolü
        self.stdout.write('⚙️ 2. Django Settings:')
        settings_vars = ['SUPABASE_URL', 'SUPABASE_ANON_KEY', 'SUPABASE_SERVICE_ROLE_KEY']
        for var in settings_vars:
            value = getattr(settings, var, None)
            status = '✅ VAR' if value else '❌ YOK'
            self.stdout.write(f"   {var}: {status}")
            if value and var != 'SUPABASE_SERVICE_ROLE_KEY':  # Key'i gösterme
                self.stdout.write(f"      Value: {value[:50]}...")
        self.stdout.write('')
        
        # 3. Supabase Python modülü kontrolü
        self.stdout.write('🐍 3. Supabase Python Modülü:')
        try:
            from supabase import create_client
            self.stdout.write('   ✅ supabase modülü import edilebildi')
            
            # Client oluşturma testi
            supabase_url = os.getenv('SUPABASE_URL') or getattr(settings, 'SUPABASE_URL', None)
            supabase_key = os.getenv('SUPABASE_ANON_KEY') or getattr(settings, 'SUPABASE_ANON_KEY', None)
            
            if supabase_url and supabase_key:
                try:
                    client = create_client(supabase_url, supabase_key)
                    self.stdout.write('   ✅ Supabase client oluşturulabildi')
                    
                    # Bucket listesi testi
                    try:
                        buckets = client.storage.list_buckets()
                        self.stdout.write(f"   ✅ Bucket listesi alınabildi: {len(buckets)} bucket")
                        for bucket in buckets:
                            self.stdout.write(f"      - {bucket.name}")
                    except Exception as bucket_error:
                        self.stdout.write(f"   ❌ Bucket listesi alınamadı: {bucket_error}")
                        
                except Exception as client_error:
                    self.stdout.write(f"   ❌ Supabase client oluşturulamadı: {client_error}")
            else:
                self.stdout.write('   ❌ Supabase URL veya Key eksik')
                
        except ImportError as import_error:
            self.stdout.write(f"   ❌ supabase modülü import edilemedi: {import_error}")
            self.stdout.write('   💡 Çözüm: pip install supabase')
        self.stdout.write('')
        
        # 4. SupabaseStorageService test
        self.stdout.write('🚀 4. SupabaseStorageService Test:')
        try:
            from users.services.supabase_storage_service import SupabaseStorageService
            storage_service = SupabaseStorageService()
            
            if storage_service.is_available:
                self.stdout.write('   ✅ SupabaseStorageService başarıyla başlatıldı')
                
                # Connection test
                connection_test = storage_service.test_connection()
                if connection_test['success']:
                    self.stdout.write('   ✅ Connection test başarılı')
                    self.stdout.write(f"      Bucket'lar: {connection_test['buckets']}")
                else:
                    self.stdout.write(f"   ❌ Connection test başarısız: {connection_test['error']}")
            else:
                self.stdout.write('   ❌ SupabaseStorageService başlatılamadı')
                
        except Exception as service_error:
            self.stdout.write(f"   ❌ SupabaseStorageService test hatası: {service_error}")
        self.stdout.write('')
        
        # 5. Test upload (opsiyonel)
        if options['test_upload']:
            self.stdout.write('📤 5. Test Upload (opsiyonel):')
            self.stdout.write('   Test upload özelliği henüz implement edilmedi')
        else:
            self.stdout.write('📤 5. Test Upload:')
            self.stdout.write('   Test upload yapılmadı (--test-upload flag ile aktif edilebilir)')
        
        self.stdout.write('')
        self.stdout.write(
            self.style.SUCCESS('🎉 Detaylı test tamamlandı!')
        )
