from django.core.management.base import BaseCommand
from django.conf import settings
from django.db import connection
import os
import time

class Command(BaseCommand):
    help = 'Supabase bağlantısını test eder'

    def handle(self, *args, **options):
        self.stdout.write("=== Supabase Bağlantı Testi ===")
        
        # 1. Environment Variables Kontrolü
        self.stdout.write("\n1. Environment Variables Kontrolü")
        supabase_url = getattr(settings, 'SUPABASE_URL', None)
        supabase_anon_key = getattr(settings, 'SUPABASE_ANON_KEY', None)
        supabase_service_key = getattr(settings, 'SUPABASE_SERVICE_KEY', None)
        
        self.stdout.write(f"SUPABASE_URL: {supabase_url}")
        self.stdout.write(f"SUPABASE_ANON_KEY: {'VAR' if supabase_anon_key else 'YOK'}")
        self.stdout.write(f"SUPABASE_SERVICE_KEY: {'VAR' if supabase_service_key else 'YOK'}")
        
        # 2. Database Bağlantı Testi
        self.stdout.write("\n2. Database Bağlantı Testi")
        try:
            with connection.cursor() as cursor:
                start_time = time.time()
                cursor.execute("SELECT 1")
                result = cursor.fetchone()
                end_time = time.time()
                
                self.stdout.write(f"✅ Database bağlantısı başarılı: {result}")
                self.stdout.write(f"⏱️ Bağlantı süresi: {end_time - start_time:.2f} saniye")
                
                # Database bilgileri
                cursor.execute("SELECT version()")
                db_version = cursor.fetchone()[0]
                self.stdout.write(f"📊 Database Version: {db_version}")
                
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"❌ Database bağlantı hatası: {str(e)}"))
            return
        
        # 3. Supabase Client Testi
        self.stdout.write("\n3. Supabase Client Testi")
        try:
            from supabase import create_client, Client
            
            if supabase_url and supabase_service_key:
                client = create_client(supabase_url, supabase_service_key)
                
                # Basit bir test sorgusu
                start_time = time.time()
                result = client.table('auth.users').select('id').limit(1).execute()
                end_time = time.time()
                
                self.stdout.write(f"✅ Supabase client bağlantısı başarılı")
                self.stdout.write(f"⏱️ Sorgu süresi: {end_time - start_time:.2f} saniye")
                self.stdout.write(f"📊 Sonuç: {len(result.data)} kayıt")
                
            else:
                self.stdout.write(self.style.ERROR("❌ Supabase credentials eksik"))
                
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"❌ Supabase client hatası: {str(e)}"))
        
        # 4. Storage Testi
        self.stdout.write("\n4. Supabase Storage Testi")
        try:
            from users.services.supabase_storage_service import SupabaseStorageService
            
            storage_service = SupabaseStorageService()
            self.stdout.write(f"Storage Service Available: {storage_service.is_available}")
            
            if storage_service.is_available:
                # Bucket'ları listele
                try:
                    buckets = storage_service.client.storage.list_buckets()
                    self.stdout.write(f"✅ Bucket'lar listelendi: {len(buckets)} adet")
                    for bucket in buckets:
                        self.stdout.write(f"  - {bucket.name}")
                except Exception as bucket_error:
                    self.stdout.write(self.style.ERROR(f"❌ Bucket listesi hatası: {str(bucket_error)}"))
            else:
                self.stdout.write(self.style.ERROR("❌ Storage servisi kullanılamıyor"))
                
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"❌ Storage test hatası: {str(e)}"))
        
        # 5. Network Connectivity Testi
        self.stdout.write("\n5. Network Connectivity Testi")
        try:
            import socket
            
            # Supabase host'una bağlantı testi
            host = "aws-1-eu-central-1.pooler.supabase.com"
            port = 6543
            
            start_time = time.time()
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(10)  # 10 saniye timeout
            
            result = sock.connect_ex((host, port))
            sock.close()
            end_time = time.time()
            
            if result == 0:
                self.stdout.write(f"✅ {host}:{port} bağlantısı başarılı")
                self.stdout.write(f"⏱️ Bağlantı süresi: {end_time - start_time:.2f} saniye")
            else:
                self.stdout.write(self.style.ERROR(f"❌ {host}:{port} bağlantısı başarısız (kod: {result})"))
                
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"❌ Network test hatası: {str(e)}"))
        
        # 6. DNS Resolution Testi
        self.stdout.write("\n6. DNS Resolution Testi")
        try:
            import socket
            
            host = "aws-1-eu-central-1.pooler.supabase.com"
            start_time = time.time()
            ip_addresses = socket.gethostbyname_ex(host)
            end_time = time.time()
            
            self.stdout.write(f"✅ DNS çözümleme başarılı: {ip_addresses[2]}")
            self.stdout.write(f"⏱️ DNS süresi: {end_time - start_time:.2f} saniye")
            
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"❌ DNS çözümleme hatası: {str(e)}"))
        
        # 7. Database Connection Pool Testi
        self.stdout.write("\n7. Database Connection Pool Testi")
        try:
            from django.db import connections
            
            # Tüm bağlantıları test et
            for conn_name in connections:
                conn = connections[conn_name]
                try:
                    with conn.cursor() as cursor:
                        cursor.execute("SELECT 1")
                        result = cursor.fetchone()
                        self.stdout.write(f"✅ {conn_name} bağlantısı başarılı")
                except Exception as conn_error:
                    self.stdout.write(self.style.ERROR(f"❌ {conn_name} bağlantı hatası: {str(conn_error)}"))
                    
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"❌ Connection pool test hatası: {str(e)}"))
        
        self.stdout.write("\n=== Test Tamamlandı ===")
        
        # 8. Öneriler
        self.stdout.write("\n8. Öneriler")
        self.stdout.write("Eğer bağlantı sorunları devam ediyorsa:")
        self.stdout.write("- Supabase dashboard'da database durumunu kontrol edin")
        self.stdout.write("- DATABASE_URL environment variable'ını kontrol edin")
        self.stdout.write("- Render.com'da environment variables'ları kontrol edin")
        self.stdout.write("- Supabase plan limitlerini kontrol edin")
        self.stdout.write("- Database connection pool ayarlarını gözden geçirin")
