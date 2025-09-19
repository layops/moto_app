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
            # Bucket'ın varlığını kontrol et
            try:
                buckets = self.client.storage.list_buckets()
                bucket_names = [bucket.name for bucket in buckets]
                if self.events_bucket not in bucket_names:
                    print(f"❌ Bucket bulunamadı: {self.events_bucket}")
                    return {
                        'success': False,
                        'error': f'Bucket bulunamadı: {self.events_bucket}'
                    }
            except Exception as bucket_error:
                print(f"⚠️ Bucket kontrolü yapılamadı: {str(bucket_error)}")
            
            # Dosya adını oluştur
            file_extension = file.name.split('.')[-1] if '.' in file.name else 'jpg'
            file_name = f"events/{event_id}/cover_{event_id}_{os.urandom(4).hex()}.{file_extension}"
            print(f"Dosya adı oluşturuldu: {file_name}")
            print(f"Dosya boyutu: {file.size} bytes")
            print(f"Content-Type: {file.content_type}")
            
            # Dosya içeriğini güvenli şekilde oku
            try:
                print(f"=== DOSYA OKUMA BAŞLADI ===")
                print(f"File type: {type(file)}")
                print(f"File attributes: {dir(file)}")
                print(f"File name: {file.name}")
                print(f"File size: {file.size}")
                print(f"File content_type: {file.content_type}")
                
                # Dosya boyutunu kontrol et
                if file.size == 0:
                    print("❌ Dosya boyutu 0 - boş dosya!")
                    return {
                        'success': False,
                        'error': 'Dosya boş - boyut 0 bytes'
                    }
                
                # Dosya içeriğini okumak için farklı yöntemler dene
                file_content = None
                
                # Yöntem 1: Normal read()
                try:
                    if hasattr(file, 'seek'):
                        file.seek(0)
                    file_content = file.read()
                    print(f"Yöntem 1 (read): {type(file_content)}, boyut: {len(file_content) if hasattr(file_content, '__len__') else 'N/A'}")
                    
                    # Boolean kontrolü
                    if isinstance(file_content, bool):
                        print(f"❌ Yöntem 1: file_content boolean: {file_content}")
                        file_content = None
                    elif file_content == b'':
                        print(f"⚠️ Yöntem 1: file_content boş bytes")
                        file_content = None
                    else:
                        print(f"✅ Yöntem 1 başarılı: {len(file_content)} bytes")
                        
                except Exception as e:
                    print(f"Yöntem 1 başarısız: {e}")
                    file_content = None
                
                # Yöntem 2: Django InMemoryUploadedFile için
                if (file_content is None or isinstance(file_content, bool)) and hasattr(file, 'file'):
                    try:
                        file.file.seek(0)
                        file_content = file.file.read()
                        print(f"Yöntem 2 (file.file.read): {type(file_content)}, boyut: {len(file_content) if hasattr(file_content, '__len__') else 'N/A'}")
                    except Exception as e:
                        print(f"Yöntem 2 başarısız: {e}")
                
                # Yöntem 3: read_bytes()
                if (file_content is None or isinstance(file_content, bool)) and hasattr(file, 'read_bytes'):
                    try:
                        if hasattr(file, 'seek'):
                            file.seek(0)
                        file_content = file.read_bytes()
                        print(f"Yöntem 3 (read_bytes): {type(file_content)}, boyut: {len(file_content) if hasattr(file_content, '__len__') else 'N/A'}")
                    except Exception as e:
                        print(f"Yöntem 3 başarısız: {e}")
                
                # Yöntem 4: chunks() kullan
                if (file_content is None or isinstance(file_content, bool)) and hasattr(file, 'chunks'):
                    try:
                        chunks = []
                        for chunk in file.chunks():
                            chunks.append(chunk)
                        file_content = b''.join(chunks)
                        print(f"Yöntem 4 (chunks): {type(file_content)}, boyut: {len(file_content) if hasattr(file_content, '__len__') else 'N/A'}")
                        
                        # Boolean kontrolü
                        if isinstance(file_content, bool):
                            print(f"❌ Yöntem 4: file_content boolean: {file_content}")
                            file_content = None
                        elif file_content == b'':
                            print(f"⚠️ Yöntem 4: file_content boş bytes")
                            file_content = None
                        else:
                            print(f"✅ Yöntem 4 başarılı: {len(file_content)} bytes")
                            
                    except Exception as e:
                        print(f"Yöntem 4 başarısız: {e}")
                        file_content = None
                
                # Yöntem 5: Geçici dosya olarak kaydet ve oku
                if (file_content is None or isinstance(file_content, bool)):
                    try:
                        import tempfile
                        print("Yöntem 5: Geçici dosya ile upload deneniyor...")
                        
                        # Geçici dosya oluştur
                        with tempfile.NamedTemporaryFile(delete=False) as temp_file:
                            # Dosyayı geçici dosyaya yaz
                            if hasattr(file, 'seek'):
                                file.seek(0)
                            for chunk in file.chunks():
                                temp_file.write(chunk)
                            temp_file.flush()
                            
                            # Geçici dosyayı oku
                            with open(temp_file.name, 'rb') as f:
                                file_content = f.read()
                            
                            # Geçici dosyayı sil
                            import os
                            os.unlink(temp_file.name)
                            
                        print(f"Yöntem 5 (temp file): {type(file_content)}, boyut: {len(file_content) if hasattr(file_content, '__len__') else 'N/A'}")
                        
                        # Boolean kontrolü
                        if isinstance(file_content, bool):
                            print(f"❌ Yöntem 5: file_content boolean: {file_content}")
                            file_content = None
                        elif file_content == b'':
                            print(f"⚠️ Yöntem 5: file_content boş bytes")
                            file_content = None
                        else:
                            print(f"✅ Yöntem 5 başarılı: {len(file_content)} bytes")
                            
                    except Exception as e:
                        print(f"Yöntem 5 başarısız: {e}")
                        file_content = None
                
                # Son kontrol
                if file_content is None or isinstance(file_content, bool):
                    print(f"❌ Tüm yöntemler başarısız, file_content: {file_content}")
                    return {
                        'success': False,
                        'error': 'Dosya içeriği okunamadı - tüm okuma yöntemleri başarısız'
                    }
                
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
                import traceback
                traceback.print_exc()
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
                
                # Supabase upload'u dene - farklı yaklaşımlar
                result = None
                
                # Yaklaşım 1: Normal upload
                try:
                    print("Yaklaşım 1: Normal upload deneniyor...")
                    result = self.client.storage.from_(self.events_bucket).upload(
                        file_name,
                        file_content,
                        file_options={
                            "content-type": content_type,
                            "upsert": True
                        }
                    )
                    print("✅ Yaklaşım 1 başarılı")
                except Exception as e1:
                    print(f"❌ Yaklaşım 1 başarısız: {e1}")
                    
                    # Yaklaşım 2: BytesIO kullan
                    try:
                        print("Yaklaşım 2: BytesIO ile upload deneniyor...")
                        from io import BytesIO
                        file_buffer = BytesIO(file_content)
                        result = self.client.storage.from_(self.events_bucket).upload(
                            file_name,
                            file_buffer.getvalue(),
                            file_options={
                                "content-type": content_type,
                                "upsert": True
                            }
                        )
                        print("✅ Yaklaşım 2 başarılı")
                    except Exception as e2:
                        print(f"❌ Yaklaşım 2 başarısız: {e2}")
                        
                        # Yaklaşım 3: Base64 encode
                        try:
                            print("Yaklaşım 3: Base64 encode ile upload deneniyor...")
                            import base64
                            encoded_content = base64.b64encode(file_content).decode('utf-8')
                            result = self.client.storage.from_(self.events_bucket).upload(
                                file_name,
                                encoded_content,
                                file_options={
                                    "content-type": content_type,
                                    "upsert": True
                                }
                            )
                            print("✅ Yaklaşım 3 başarılı")
                        except Exception as e3:
                            print(f"❌ Yaklaşım 3 başarısız: {e3}")
                            
                            # Yaklaşım 4: String olarak gönder
                            try:
                                print("Yaklaşım 4: String olarak upload deneniyor...")
                                string_content = file_content.decode('latin-1')
                                result = self.client.storage.from_(self.events_bucket).upload(
                                    file_name,
                                    string_content,
                                    file_options={
                                        "content-type": content_type,
                                        "upsert": True
                                    }
                                )
                                print("✅ Yaklaşım 4 başarılı")
                            except Exception as e4:
                                print(f"❌ Yaklaşım 4 başarısız: {e4}")
                                
                                # Tüm yaklaşımlar başarısız
                                print("❌ Tüm upload yaklaşımları başarısız")
                                raise e1  # İlk hatayı fırlat
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
