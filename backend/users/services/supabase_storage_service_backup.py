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
                {
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
                {
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
        Profil fotoğrafı yükleme sistemi ile aynı basit yaklaşım
        """
        if not self.is_available:
            return {
                'success': False,
                'error': 'Supabase Storage servisi kullanılamıyor'
            }
        
        try:
            # Dosya adını oluştur
            file_extension = file.name.split('.')[-1] if '.' in file.name else 'jpg'
            file_name = f"events/{event_id}/cover_{event_id}_{os.urandom(4).hex()}.{file_extension}"
            
            # Dosyayı basit ve güvenli şekilde oku
            try:
                print(f"🔍 Dosya okuma başlıyor: {type(file)}, name: {file.name}")
                print(f"📏 Dosya boyutu: {file.size} bytes")
                
                # Dosya boyutunu kontrol et
                if file.size == 0:
                    print("❌ Dosya boyutu 0 - boş dosya!")
                    return {
                        'success': False,
                        'error': 'Dosya boş - boyut 0 bytes'
                    }
                
                # Dosya pointer'ını başa al
                if hasattr(file, 'seek'):
                    file.seek(0)
                    print("📍 Dosya pointer başa alındı")
                
                # Dosyayı chunks() ile oku - Django'nun önerdiği yöntem
                print("🔄 chunks() metodu kullanılıyor")
                chunks = []
                for chunk in file.chunks():
                    if isinstance(chunk, bytes):
                        chunks.append(chunk)
                    else:
                        print(f"⚠️ Chunk bytes değil: {type(chunk)}")
                        break
                
                if not chunks:
                    raise ValueError("chunks() metodu boş döndü - dosya okunamadı")
                
                file_content = b''.join(chunks)
                
                if len(file_content) == 0:
                    raise ValueError("Dosya içeriği boş")
                
                # Bytes kontrolü
                if not isinstance(file_content, (bytes, bytearray)):
                    print(f"❌ Dosya içeriği bytes değil: {type(file_content)}")
                    return {
                        'success': False,
                        'error': f'Dosya içeriği bytes formatında değil: {type(file_content)}'
                    }
                
                print(f"✅ Dosya içeriği başarıyla okundu: {len(file_content)} bytes")
                
            except Exception as read_error:
                print(f"❌ Dosya okuma hatası: {str(read_error)}")
                return {
                    'success': False,
                    'error': f'Dosya okunamadı: {str(read_error)}'
                }
            
            # Dosyayı yükle
            try:
                print(f"=== SUPABASE UPLOAD BAŞLADI ===")
                print(f"File name: {file_name}")
                print(f"File content type: {type(file_content)}")
                print(f"File content length: {len(file_content) if file_content else 'None'}")
                
                # Dosya içeriğinin bytes olduğundan emin ol
                if not isinstance(file_content, (bytes, bytearray)):
                    print(f"❌ Dosya içeriği bytes değil: {type(file_content)}")
                    return {
                        'success': False,
                        'error': f'Dosya içeriği bytes formatında değil: {type(file_content)}'
                    }
                
                # Content-type'ı kontrol et
                content_type = getattr(file, 'content_type', None)
                if not content_type or not isinstance(content_type, str):
                    print("⚠️ Content-type eksik veya geçersiz, varsayılan olarak image/jpeg kullanılıyor")
                    content_type = 'image/jpeg'
                
                print(f"Content-type: {content_type}")
                print(f"Upload options: content-type={content_type}, upsert=True")
                
                # Supabase upload - basit ve doğru yaklaşım
                print("📤 Supabase upload başlıyor...")
                result = self.client.storage.from_(self.events_bucket).upload(
                    file_name,
                    file_content,
                    {
                        "content-type": content_type,
                        "upsert": True
                    }
                )
                print("✅ Upload tamamlandı")
                # Result kontrolü
                if result is None:
                    print("❌ Upload result None döndü")
                    return {
                        'success': False,
                        'error': 'Upload işlemi başarısız - result None'
                    }
                
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
                print(f"❌ Upload error args: {upload_error.args}")
                
                # Özel hata mesajları
                error_message = str(upload_error)
                if "'bool' object has no attribute 'encode'" in error_message:
                    error_message = "Dosya içeriği boolean değer olarak algılandı. Dosya formatı desteklenmiyor."
                elif "Connection refused" in error_message:
                    error_message = "Supabase sunucusuna bağlanılamıyor. Lütfen daha sonra tekrar deneyin."
                elif "timeout" in error_message.lower():
                    error_message = "Dosya yükleme zaman aşımına uğradı. Dosya çok büyük olabilir."
                
                import traceback
                traceback.print_exc()
                return {
                    'success': False,
                    'error': f'Upload hatası: {error_message}'
                }
            
            # Upload başarılı mı kontrol et
            if result:
                # Supabase response'unu daha detaylı kontrol et
                upload_success = True
                if hasattr(result, 'data') and result.data:
                    # data içinde hata var mı kontrol et
                    if isinstance(result.data, dict) and result.data.get('error'):
                        upload_success = False
                        print(f"❌ Upload response'da hata: {result.data['error']}")
                
                if upload_success:
                    try:
                        # Public URL'i al
                        public_url = self.client.storage.from_(self.events_bucket).get_public_url(file_name)
                        print(f"Public URL oluşturuldu: {public_url}")
                        
                        # URL'in erişilebilir olduğunu test et
                        try:
                            import requests
                            test_response = requests.head(public_url, timeout=5)
                            if test_response.status_code == 200:
                                print("✅ URL erişilebilir")
                            else:
                                print(f"⚠️ URL erişilemez: {test_response.status_code}")
                        except ImportError:
                            print("⚠️ requests kütüphanesi bulunamadı, URL test edilemedi")
                        except Exception as test_error:
                            print(f"⚠️ URL test edilemedi: {str(test_error)}")
                        
                        logger.info(f"Event kapak fotoğrafı başarıyla yüklendi: {file_name}")
                        return {
                            'success': True,
                            'url': public_url,
                            'file_name': file_name
                        }
                    except Exception as url_error:
                        print(f"❌ Public URL oluşturma hatası: {str(url_error)}")
                        return {
                            'success': True,
                            'url': None,
                            'file_name': file_name,
                            'warning': f'Dosya yüklendi ama URL oluşturulamadı: {str(url_error)}'
                        }
                else:
                    print("❌ Upload başarısız")
                    return {
                        'success': False,
                        'error': 'Upload başarısız'
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
