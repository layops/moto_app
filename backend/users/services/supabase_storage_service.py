"""
Supabase Storage Service
Profil fotoğrafı ve kapak fotoğrafı yükleme için Supabase Storage kullanımı
"""
import os
import logging
from django.conf import settings
from supabase import create_client, Client
from typing import Optional, Dict, Any

logger = logging.getLogger(__name__)

class SupabaseStorageService:
    def __init__(self):
        self.client: Optional[Client] = None
        self.is_available = False
        
        try:
            self.supabase_url = getattr(settings, 'SUPABASE_URL', None)
            self.supabase_service_key = getattr(settings, 'SUPABASE_SERVICE_KEY', None)
            self.profile_bucket = getattr(settings, 'SUPABASE_BUCKET', 'profile_pictures')
            self.cover_bucket = getattr(settings, 'SUPABASE_COVER_BUCKET', 'cover_pictures')
            self.events_bucket = getattr(settings, 'SUPABASE_EVENTS_BUCKET', 'events_pictures')
            
            print(f"=== SUPABASE STORAGE SERVICE INIT ===")
            print(f"SUPABASE_URL: {self.supabase_url}")
            print(f"SUPABASE_SERVICE_KEY: {'VAR' if self.supabase_service_key else 'YOK'}")
            print(f"events_bucket: {self.events_bucket}")
            
            if self.supabase_url and self.supabase_service_key:
                try:
                    self.client = create_client(self.supabase_url, self.supabase_service_key)
                    self.is_available = True
                    print("✅ Supabase Storage servisi başarıyla başlatıldı")
                    
                    # Bağlantıyı test et
                    self._test_connection()
                    
                    # Bucket'ları kontrol et ve oluştur
                    self._ensure_buckets_exist()
                    
                    logger.info("Supabase Storage servisi başarıyla başlatıldı")
                except Exception as client_error:
                    print(f"❌ Supabase client oluşturma hatası: {str(client_error)}")
                    self.is_available = False
                    raise client_error
            else:
                print("❌ Supabase Storage credentials eksik")
                print(f"URL var mı: {bool(self.supabase_url)}")
                print(f"SERVICE_KEY var mı: {bool(self.supabase_service_key)}")
                logger.warning("Supabase Storage credentials eksik")
                
        except Exception as e:
            print(f"❌ Supabase Storage servisi başlatılamadı: {e}")
            logger.error(f"Supabase Storage servisi başlatılamadı: {e}")
            self.is_available = False

    def _test_connection(self):
        """Supabase bağlantısını test et"""
        try:
            print("🔍 Supabase bağlantısı test ediliyor...")
            # Basit bir storage işlemi ile bağlantıyı test et
            buckets = self.client.storage.list_buckets()
            print(f"✅ Supabase bağlantısı başarılı, {len(buckets)} bucket bulundu")
        except Exception as e:
            print(f"❌ Supabase bağlantı testi başarısız: {str(e)}")
            raise e

    def _ensure_buckets_exist(self):
        """Gerekli bucket'ların var olduğundan emin ol"""
        try:
            print("=== BUCKET KONTROL VE OLUŞTURMA ===")
            
            # Mevcut bucket'ları listele
            existing_buckets = self.client.storage.list_buckets()
            existing_bucket_names = [bucket.name for bucket in existing_buckets]
            print(f"Mevcut bucket'lar: {existing_bucket_names}")
            
            # Gerekli bucket'lar
            required_buckets = [
                self.profile_bucket,
                self.cover_bucket, 
                self.events_bucket
            ]
            
            for bucket_name in required_buckets:
                if bucket_name not in existing_bucket_names:
                    print(f"Bucket oluşturuluyor: {bucket_name}")
                    try:
                        self.client.storage.create_bucket(bucket_name, public=True)
                        print(f"✅ Bucket oluşturuldu: {bucket_name}")
                    except Exception as e:
                        print(f"❌ Bucket oluşturulamadı {bucket_name}: {e}")
                else:
                    print(f"✅ Bucket mevcut: {bucket_name}")
                    
                    # Bucket'ın public olup olmadığını kontrol et
                    try:
                        bucket_info = self.client.storage.get_bucket(bucket_name)
                        print(f"Bucket {bucket_name} bilgileri: {bucket_info}")
                    except Exception as e:
                        print(f"Bucket {bucket_name} bilgileri alınamadı: {e}")
                    
        except Exception as e:
            print(f"❌ Bucket kontrol hatası: {e}")

    def upload_profile_picture(self, file, username: str) -> Dict[str, Any]:
        """
        Profil fotoğrafını Supabase Storage'a yükler
        """
        if not self.is_available:
            return {
                'success': False,
                'error': 'Supabase Storage servisi kullanılamıyor'
            }
        
        try:
            # Dosya adını oluştur
            file_extension = file.name.split('.')[-1] if '.' in file.name else 'jpg'
            file_name = f"{username}/profile_{username}_{os.urandom(4).hex()}.{file_extension}"
            
            # Dosyayı yükle
            result = self.client.storage.from_(self.profile_bucket).upload(
                file_name,
                file.read(),
                file_options={
                    "content-type": file.content_type,
                    "upsert": True  # Aynı isimde dosya varsa üzerine yaz
                }
            )
            
            if result:
                # Public URL'i al
                public_url = self.client.storage.from_(self.profile_bucket).get_public_url(file_name)
                
                logger.info(f"Profil fotoğrafı başarıyla yüklendi: {file_name}")
                return {
                    'success': True,
                    'url': public_url,
                    'file_name': file_name
                }
            else:
                return {
                    'success': False,
                    'error': 'Dosya yükleme başarısız'
                }
                
        except Exception as e:
            logger.error(f"Profil fotoğrafı yükleme hatası: {e}")
            return {
                'success': False,
                'error': f'Dosya yükleme hatası: {str(e)}'
            }

    def upload_cover_picture(self, file, username: str) -> Dict[str, Any]:
        """
        Kapak fotoğrafını Supabase Storage'a yükler
        """
        if not self.is_available:
            return {
                'success': False,
                'error': 'Supabase Storage servisi kullanılamıyor'
            }
        
        try:
            # Dosya adını oluştur
            file_extension = file.name.split('.')[-1] if '.' in file.name else 'jpg'
            file_name = f"{username}/cover_{username}_{os.urandom(4).hex()}.{file_extension}"
            
            # Dosyayı yükle
            result = self.client.storage.from_(self.cover_bucket).upload(
                file_name,
                file.read(),
                file_options={
                    "content-type": file.content_type,
                    "upsert": True  # Aynı isimde dosya varsa üzerine yaz
                }
            )
            
            if result:
                # Public URL'i al
                public_url = self.client.storage.from_(self.cover_bucket).get_public_url(file_name)
                
                logger.info(f"Kapak fotoğrafı başarıyla yüklendi: {file_name}")
                return {
                    'success': True,
                    'url': public_url,
                    'file_name': file_name
                }
            else:
                return {
                    'success': False,
                    'error': 'Dosya yükleme başarısız'
                }
                
        except Exception as e:
            logger.error(f"Kapak fotoğrafı yükleme hatası: {e}")
            return {
                'success': False,
                'error': f'Dosya yükleme hatası: {str(e)}'
            }

    def upload_event_picture(self, file, event_id: str) -> Dict[str, Any]:
        """
        Event kapak fotoğrafını Supabase Storage'a yükler
        """
        print(f"=== SUPABASE STORAGE UPLOAD BAŞLADI ===")
        print(f"is_available: {self.is_available}")
        print(f"events_bucket: {self.events_bucket}")
        print(f"event_id: {event_id}")
        
        if not self.is_available:
            print("❌ Supabase Storage servisi kullanılamıyor")
            return {
                'success': False,
                'error': 'Supabase Storage servisi kullanılamıyor'
            }
        
        try:
            # Dosya adını oluştur
            file_extension = file.name.split('.')[-1] if '.' in file.name else 'jpg'
            file_name = f"events/{event_id}/cover_{event_id}_{os.urandom(4).hex()}.{file_extension}"
            print(f"Dosya adı oluşturuldu: {file_name}")
            print(f"Dosya boyutu: {file.size} bytes")
            print(f"Content-Type: {file.content_type}")
            
            # Dosyayı yükle - events_bucket kullan
            print(f"Supabase'e yükleme başlıyor...")
            
            # File pointer'ı başa al
            file.seek(0)
            file_content = file.read()
            print(f"Dosya içeriği okundu, boyut: {len(file_content)} bytes")
            
            try:
                result = self.client.storage.from_(self.events_bucket).upload(
                    file_name,
                    file_content,
                    file_options={
                        "content-type": file.content_type,
                        "upsert": True  # Aynı isimde dosya varsa üzerine yaz
                    }
                )
                print(f"Upload result: {result}")
                print(f"Upload result type: {type(result)}")
                
                # Result'un detaylarını kontrol et
                if hasattr(result, 'data'):
                    print(f"Upload result data: {result.data}")
                if hasattr(result, 'status_code'):
                    print(f"Upload status code: {result.status_code}")
                    
            except Exception as upload_error:
                print(f"❌ Upload işlemi sırasında hata: {str(upload_error)}")
                print(f"❌ Upload error type: {type(upload_error)}")
                import traceback
                traceback.print_exc()
                raise upload_error
            
            if result:
                try:
                    # Public URL'i al - events_bucket kullan
                    public_url = self.client.storage.from_(self.events_bucket).get_public_url(file_name)
                    print(f"Public URL oluşturuldu: {public_url}")
                    
                    logger.info(f"Event kapak fotoğrafı başarıyla yüklendi: {file_name}")
                    return {
                        'success': True,
                        'url': public_url,
                        'file_name': file_name
                    }
                except Exception as url_error:
                    print(f"❌ Public URL oluşturma hatası: {str(url_error)}")
                    # URL oluşturulamasa bile dosya yüklenmiş olabilir
                    return {
                        'success': True,
                        'url': None,
                        'file_name': file_name,
                        'warning': f'Dosya yüklendi ama URL oluşturulamadı: {str(url_error)}'
                    }
            else:
                print("❌ Upload result False döndü")
                return {
                    'success': False,
                    'error': 'Dosya yükleme başarısız'
                }
                
        except Exception as e:
            print(f"❌ Exception oluştu: {str(e)}")
            logger.error(f"Event kapak fotoğrafı yükleme hatası: {e}")
            return {
                'success': False,
                'error': f'Dosya yükleme hatası: {str(e)}'
            }

    def delete_file(self, bucket: str, file_name: str) -> bool:
        """
        Supabase Storage'dan dosya siler
        """
        if not self.is_available:
            return False
        
        try:
            result = self.client.storage.from_(bucket).remove([file_name])
            logger.info(f"Dosya silindi: {bucket}/{file_name}")
            return True
        except Exception as e:
            logger.error(f"Dosya silme hatası: {e}")
            return False
