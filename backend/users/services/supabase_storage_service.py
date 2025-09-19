import os
import logging
from typing import Dict, Any, Optional
from supabase import Client, create_client
from django.conf import settings

logger = logging.getLogger(__name__)

def get_safe_content_type(file) -> str:
    """
    Django file object'inden güvenli content_type alır.
    Django bazen content_type'ı boolean olarak döndürür, bu durumu handle eder.
    """
    # İlk olarak content_type'ı al
    content_type = getattr(file, 'content_type', None)
    
    # Eğer boolean ise, dosya adından format çıkar
    if isinstance(content_type, bool):
        file_name = getattr(file, 'name', '')
        if file_name.lower().endswith(('.jpg', '.jpeg')):
            return 'image/jpeg'
        elif file_name.lower().endswith('.png'):
            return 'image/png'
        elif file_name.lower().endswith('.gif'):
            return 'image/gif'
        elif file_name.lower().endswith('.webp'):
            return 'image/webp'
        else:
            return 'image/jpeg'  # Varsayılan
    
    # Eğer None veya boş string ise
    if not content_type:
        file_name = getattr(file, 'name', '')
        if file_name.lower().endswith(('.jpg', '.jpeg')):
            return 'image/jpeg'
        elif file_name.lower().endswith('.png'):
            return 'image/png'
        elif file_name.lower().endswith('.gif'):
            return 'image/gif'
        elif file_name.lower().endswith('.webp'):
            return 'image/webp'
        else:
            return 'image/jpeg'  # Varsayılan
    
    # Normal string ise olduğu gibi döndür
    return content_type

class SupabaseStorageService:
    def __init__(self):
        self.client: Optional[Client] = None
        self.profile_bucket = "profile_pictures"           # ✅ Mevcut
        self.events_bucket = "events_pictures"             # ✅ Mevcut
        self.cover_bucket = "cover_pictures"               # ✅ Mevcut
        self.groups_bucket = "groups_profile_pictures"     # ✅ Mevcut
        self.posts_bucket = "group_posts_images"           # ✅ Mevcut
        self.bikes_bucket = "bikes_images"                 # ✅ Mevcut
        self.is_available = False
        
        try:
            # Supabase konfigürasyonu - önce environment variables, sonra settings
            supabase_url = os.getenv('SUPABASE_URL') or getattr(settings, 'SUPABASE_URL', None)
            supabase_key = os.getenv('SUPABASE_ANON_KEY') or getattr(settings, 'SUPABASE_ANON_KEY', None)
            
            # Service role key'i de dene (Storage işlemleri için gerekli)
            if not supabase_key:
                supabase_key = os.getenv('SUPABASE_SERVICE_ROLE_KEY') or getattr(settings, 'SUPABASE_SERVICE_ROLE_KEY', None)
            
            # Storage işlemleri için SERVICE_ROLE_KEY kullan
            if supabase_key == os.getenv('SUPABASE_ANON_KEY'):
                supabase_key = os.getenv('SUPABASE_SERVICE_ROLE_KEY') or getattr(settings, 'SUPABASE_SERVICE_ROLE_KEY', None)
                logger.info("🔄 Storage işlemleri için SERVICE_ROLE_KEY kullanılıyor")
            
            logger.info(f"Supabase URL: {supabase_url}")
            logger.info(f"Supabase Key: {'VAR' if supabase_key else 'YOK'}")
            
            if supabase_url and supabase_key:
                # Supabase client'ı oluştur
                try:
                    self.client = create_client(supabase_url, supabase_key)
                    self.is_available = True
                    logger.info("✅ Supabase Storage servisi başlatıldı")
                    
                    # Bucket'ları kontrol et (opsiyonel - hata olursa devam et)
                    try:
                        self._check_buckets()
                    except Exception as bucket_error:
                        logger.warning(f"⚠️ Bucket kontrolü başarısız ama servis aktif: {bucket_error}")
                        
                except ImportError as import_error:
                    logger.error(f"❌ Supabase modülü bulunamadı: {import_error}")
                    logger.error("💡 Çözüm: pip install supabase")
                    self.is_available = False
                except Exception as client_error:
                    logger.error(f"❌ Supabase client oluşturma hatası: {client_error}")
                    self.is_available = False
            else:
                logger.warning("❌ Supabase konfigürasyonu bulunamadı")
                logger.warning(f"URL: {supabase_url}, Key: {'VAR' if supabase_key else 'YOK'}")
                self.is_available = False
                
        except Exception as e:
            logger.error(f"❌ Supabase Storage servisi başlatılamadı: {e}")
            self.is_available = False

    def test_connection(self) -> Dict[str, Any]:
        """Supabase bağlantısını test et"""
        if not self.is_available:
            return {
                'success': False,
                'error': 'Supabase Storage servisi kullanılamıyor'
            }
        
        try:
            # Bucket listesi al
            buckets = self.client.storage.list_buckets()
            bucket_names = [bucket.name for bucket in buckets]
            
            return {
                'success': True,
                'buckets': bucket_names,
                'total_buckets': len(buckets),
                'required_buckets': [
                    self.profile_bucket,
                    self.events_bucket,
                    self.cover_bucket,
                    self.groups_bucket,
                    self.posts_bucket,
                    self.bikes_bucket
                ]
            }
        except Exception as e:
            logger.error(f"❌ Supabase connection test hatası: {e}")
            return {
                'success': False,
                'error': f'Connection test failed: {str(e)}'
            }

    def _check_buckets(self):
        """Bucket'ların varlığını kontrol et"""
        try:
            buckets = self.client.storage.list_buckets()
            bucket_names = [bucket.name for bucket in buckets]
            logger.info(f"📁 Mevcut bucket'lar: {bucket_names}")
            
            # Tüm bucket'ları kontrol et
            all_buckets = [
                self.profile_bucket,
                self.events_bucket, 
                self.cover_bucket,
                self.groups_bucket,
                self.posts_bucket,
                self.bikes_bucket
            ]
            
            for bucket_name in all_buckets:
                if bucket_name not in bucket_names:
                    logger.warning(f"⚠️ {bucket_name} bucket bulunamadı")
                else:
                    logger.info(f"✅ {bucket_name} bucket mevcut")
                
        except Exception as e:
            logger.error(f"❌ Bucket kontrol hatası: {e}")

    def _read_file_safely(self, file) -> bytes:
        """file.chunks() kullanarak güvenli şekilde dosya oku - boolean hatası %100 çözülür"""
        try:
            logger.info(f"🔍 Dosya okuma başlıyor: {type(file)}, name: {getattr(file, 'name', 'N/A')}")
            
            # Dosya boyutunu kontrol et
            file_size = getattr(file, 'size', 0)
            logger.info(f"📏 Dosya boyutu: {file_size} bytes")
            
            if file_size == 0:
                raise ValueError("Dosya boyutu 0 - boş dosya")
            
            # Dosya pointer'ını başa al
            if hasattr(file, 'seek'):
                file.seek(0)
                logger.info("📍 Dosya pointer başa alındı")
            
            # chunks() metodu kullan - Django'nun önerdiği ve en güvenli yöntem
            logger.info("🔄 chunks() metodu kullanılıyor")
            chunks = []
            
            for chunk in file.chunks():
                if isinstance(chunk, bytes):
                    chunks.append(chunk)
                else:
                    logger.warning(f"⚠️ Chunk bytes değil: {type(chunk)}")
                    break
            
            if not chunks:
                raise ValueError("chunks() metodu boş döndü - dosya okunamadı")
            
            file_content = b''.join(chunks)
            
            if len(file_content) == 0:
                raise ValueError("Dosya içeriği boş")
            
            logger.info(f"✅ chunks() ile başarıyla okundu: {len(file_content)} bytes")
            return file_content
            
        except Exception as e:
            logger.error(f"❌ Dosya okuma hatası: {e}")
            logger.error(f"❌ Dosya tipi: {type(file)}")
            raise

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
            
            # Dosyayı güvenli şekilde oku
            file_content = self._read_file_safely(file)
            
            # Dosya içeriğinin bytes olduğunu tekrar kontrol et
            if not isinstance(file_content, bytes):
                logger.error(f"❌ Dosya içeriği bytes değil: {type(file_content)}")
                return {
                    'success': False,
                    'error': f'Dosya içeriği geçersiz tip: {type(file_content)}'
                }
            
            # Dosyayı yükle
            try:
                # Content type'ı güvenli şekilde al
                content_type = get_safe_content_type(file)
                
                # Content type'ın string olduğunu kontrol et
                if not isinstance(content_type, str):
                    logger.error(f"❌ Content type string değil: {type(content_type)} = {content_type}")
                    content_type = 'image/jpeg'  # Varsayılan
                
                logger.info(f"📤 Upload başlıyor: {file_name}, content_type: {content_type}, file_size: {len(file_content)} bytes")
                
                result = self.client.storage.from_(self.profile_bucket).upload(
                    file_name,
                    file_content,
                    file_options={
                        "content-type": content_type,
                        "upsert": True  # Aynı isimde dosya varsa üzerine yaz
                    }
                )
                
                # Result'ı kontrol et
                if result is None:
                    logger.error("❌ Supabase upload result None döndü")
                    return {
                        'success': False,
                        'error': 'Supabase upload result None döndü'
                    }
                
                # Result'ın tipini kontrol et
                if isinstance(result, bool):
                    if result:
                        logger.info("✅ Supabase upload başarılı (boolean True)")
                    else:
                        logger.error("❌ Supabase upload başarısız (boolean False)")
                        return {
                            'success': False,
                            'error': 'Supabase upload başarısız (boolean False)'
                        }
                else:
                    logger.info(f"✅ Supabase upload result: {type(result)}")
                    
            except Exception as upload_error:
                logger.error(f"❌ Supabase upload API hatası: {upload_error}")
                return {
                    'success': False,
                    'error': f'Supabase upload hatası: {str(upload_error)}'
                }
            
            # Result başarılı ise public URL'i al
            if result or (isinstance(result, bool) and result):
                try:
                    # Public URL'i al
                    public_url = self.client.storage.from_(self.profile_bucket).get_public_url(file_name)
                    
                    logger.info(f"✅ Profil fotoğrafı başarıyla yüklendi: {file_name}")
                    return {
                        'success': True,
                        'url': public_url,
                        'file_name': file_name
                    }
                except Exception as url_error:
                    logger.error(f"❌ Public URL alma hatası: {url_error}")
                    return {
                        'success': False,
                        'error': f'Public URL alma hatası: {str(url_error)}'
                    }
            else:
                logger.error("❌ Supabase upload result boş")
                return {
                    'success': False,
                    'error': 'Dosya yükleme başarısız - result boş'
                }
                
        except Exception as e:
            logger.error(f"❌ Profil fotoğrafı yükleme hatası: {e}")
            return {
                'success': False,
                'error': f'Dosya yükleme hatası: {str(e)}'
            }

    def upload_event_picture(self, file, event_id: str) -> Dict[str, Any]:
        """
        Event kapak fotoğrafını Supabase Storage'a yükler
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
            
            # Dosyayı güvenli şekilde oku
            file_content = self._read_file_safely(file)
            
            # Dosya içeriğinin bytes olduğunu tekrar kontrol et
            if not isinstance(file_content, bytes):
                logger.error(f"❌ Dosya içeriği bytes değil: {type(file_content)}")
                return {
                    'success': False,
                    'error': f'Dosya içeriği geçersiz tip: {type(file_content)}'
                }
            
            # Dosyayı yükle
            try:
                # Content type'ı güvenli şekilde al
                content_type = get_safe_content_type(file)
                
                # Content type'ın string olduğunu kontrol et
                if not isinstance(content_type, str):
                    logger.error(f"❌ Content type string değil: {type(content_type)} = {content_type}")
                    content_type = 'image/jpeg'  # Varsayılan
                
                logger.info(f"📤 Event upload başlıyor: {file_name}, content_type: {content_type}, file_size: {len(file_content)} bytes")
                
                result = self.client.storage.from_(self.events_bucket).upload(
                    file_name,
                    file_content,
                    file_options={
                        "content-type": content_type,
                        "upsert": True
                    }
                )
            except Exception as upload_error:
                logger.error(f"❌ Supabase event upload API hatası: {upload_error}")
                return {
                    'success': False,
                    'error': f'Supabase event upload hatası: {str(upload_error)}'
                }
            
            if result:
                # Public URL'i al
                public_url = self.client.storage.from_(self.events_bucket).get_public_url(file_name)
                
                logger.info(f"✅ Event resmi başarıyla yüklendi: {file_name}")
                return {
                    'success': True,
                    'url': public_url,
                    'file_name': file_name
                }
            else:
                logger.error("❌ Supabase upload result boş")
                return {
                    'success': False,
                    'error': 'Dosya yükleme başarısız - result boş'
                }
                
        except Exception as e:
            logger.error(f"❌ Event resmi yükleme hatası: {e}")
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
            
            # Dosyayı güvenli şekilde oku
            file_content = self._read_file_safely(file)
            
            # Dosya içeriğinin bytes olduğunu tekrar kontrol et
            if not isinstance(file_content, bytes):
                logger.error(f"❌ Dosya içeriği bytes değil: {type(file_content)}")
                return {
                    'success': False,
                    'error': f'Dosya içeriği geçersiz tip: {type(file_content)}'
                }
            
            # Dosyayı yükle
            try:
                # Content type'ı güvenli şekilde al
                content_type = get_safe_content_type(file)
                
                # Content type'ın string olduğunu kontrol et
                if not isinstance(content_type, str):
                    logger.error(f"❌ Content type string değil: {type(content_type)} = {content_type}")
                    content_type = 'image/jpeg'  # Varsayılan
                
                logger.info(f"📤 Cover upload başlıyor: {file_name}, content_type: {content_type}, file_size: {len(file_content)} bytes")
                
                result = self.client.storage.from_(self.cover_bucket).upload(
                    file_name,
                    file_content,
                    file_options={
                        "content-type": content_type,
                        "upsert": True
                    }
                )
            except Exception as upload_error:
                logger.error(f"❌ Supabase cover upload API hatası: {upload_error}")
                return {
                    'success': False,
                    'error': f'Supabase cover upload hatası: {str(upload_error)}'
                }
            
            if result:
                # Public URL'i al
                public_url = self.client.storage.from_(self.cover_bucket).get_public_url(file_name)
                
                logger.info(f"✅ Kapak fotoğrafı başarıyla yüklendi: {file_name}")
                return {
                    'success': True,
                    'url': public_url,
                    'file_name': file_name
                }
            else:
                logger.error("❌ Supabase upload result boş")
                return {
                    'success': False,
                    'error': 'Dosya yükleme başarısız - result boş'
                }
                
        except Exception as e:
            logger.error(f"❌ Kapak fotoğrafı yükleme hatası: {e}")
            return {
                'success': False,
                'error': f'Dosya yükleme hatası: {str(e)}'
            }

    def upload_group_picture(self, file, group_id: str) -> Dict[str, Any]:
        """
        Grup profil fotoğrafını Supabase Storage'a yükler
        """
        if not self.is_available:
            return {
                'success': False,
                'error': 'Supabase Storage servisi kullanılamıyor'
            }
        
        try:
            # Dosya adını oluştur
            file_extension = file.name.split('.')[-1] if '.' in file.name else 'jpg'
            file_name = f"groups/{group_id}/profile_{group_id}_{os.urandom(4).hex()}.{file_extension}"
            
            # Dosyayı güvenli şekilde oku
            file_content = self._read_file_safely(file)
            
            # Dosya içeriğinin bytes olduğunu tekrar kontrol et
            if not isinstance(file_content, bytes):
                logger.error(f"❌ Dosya içeriği bytes değil: {type(file_content)}")
                return {
                    'success': False,
                    'error': f'Dosya içeriği geçersiz tip: {type(file_content)}'
                }
            
            # Dosyayı yükle
            try:
                # Content type'ı güvenli şekilde al
                content_type = get_safe_content_type(file)
                
                # Content type'ın string olduğunu kontrol et
                if not isinstance(content_type, str):
                    logger.error(f"❌ Content type string değil: {type(content_type)} = {content_type}")
                    content_type = 'image/jpeg'  # Varsayılan
                
                logger.info(f"📤 Group upload başlıyor: {file_name}, content_type: {content_type}, file_size: {len(file_content)} bytes")
                
                result = self.client.storage.from_(self.groups_bucket).upload(
                    file_name,
                    file_content,
                    file_options={
                        "content-type": content_type,
                        "upsert": True
                    }
                )
            except Exception as upload_error:
                logger.error(f"❌ Supabase group upload API hatası: {upload_error}")
                return {
                    'success': False,
                    'error': f'Supabase group upload hatası: {str(upload_error)}'
                }
            
            if result:
                # Public URL'i al
                public_url = self.client.storage.from_(self.groups_bucket).get_public_url(file_name)
                
                logger.info(f"✅ Grup profil fotoğrafı başarıyla yüklendi: {file_name}")
                return {
                    'success': True,
                    'url': public_url,
                    'file_name': file_name
                }
            else:
                logger.error("❌ Supabase upload result boş")
                return {
                    'success': False,
                    'error': 'Dosya yükleme başarısız - result boş'
                }
                
        except Exception as e:
            logger.error(f"❌ Grup profil fotoğrafı yükleme hatası: {e}")
            return {
                'success': False,
                'error': f'Dosya yükleme hatası: {str(e)}'
            }

    def upload_post_image(self, file, post_id: str) -> Dict[str, Any]:
        """
        Grup post resmini Supabase Storage'a yükler
        """
        if not self.is_available:
            return {
                'success': False,
                'error': 'Supabase Storage servisi kullanılamıyor'
            }
        
        try:
            # Dosya adını oluştur
            file_extension = file.name.split('.')[-1] if '.' in file.name else 'jpg'
            file_name = f"posts/{post_id}/image_{post_id}_{os.urandom(4).hex()}.{file_extension}"
            
            # Dosyayı güvenli şekilde oku
            file_content = self._read_file_safely(file)
            
            # Dosya içeriğinin bytes olduğunu tekrar kontrol et
            if not isinstance(file_content, bytes):
                logger.error(f"❌ Dosya içeriği bytes değil: {type(file_content)}")
                return {
                    'success': False,
                    'error': f'Dosya içeriği geçersiz tip: {type(file_content)}'
                }
            
            # Dosyayı yükle
            try:
                # Content type'ı güvenli şekilde al
                content_type = get_safe_content_type(file)
                
                # Content type'ın string olduğunu kontrol et
                if not isinstance(content_type, str):
                    logger.error(f"❌ Content type string değil: {type(content_type)} = {content_type}")
                    content_type = 'image/jpeg'  # Varsayılan
                
                logger.info(f"📤 Post upload başlıyor: {file_name}, content_type: {content_type}, file_size: {len(file_content)} bytes")
                
                result = self.client.storage.from_(self.posts_bucket).upload(
                    file_name,
                    file_content,
                    file_options={
                        "content-type": content_type,
                        "upsert": True
                    }
                )
            except Exception as upload_error:
                logger.error(f"❌ Supabase post upload API hatası: {upload_error}")
                return {
                    'success': False,
                    'error': f'Supabase post upload hatası: {str(upload_error)}'
                }
            
            if result:
                # Public URL'i al
                public_url = self.client.storage.from_(self.posts_bucket).get_public_url(file_name)
                
                logger.info(f"✅ Post resmi başarıyla yüklendi: {file_name}")
                return {
                    'success': True,
                    'url': public_url,
                    'file_name': file_name
                }
            else:
                logger.error("❌ Supabase upload result boş")
                return {
                    'success': False,
                    'error': 'Dosya yükleme başarısız - result boş'
                }
                
        except Exception as e:
            logger.error(f"❌ Post resmi yükleme hatası: {e}")
            return {
                'success': False,
                'error': f'Dosya yükleme hatası: {str(e)}'
            }

    def upload_bike_image(self, file, bike_id: str) -> Dict[str, Any]:
        """
        Motosiklet resmini Supabase Storage'a yükler
        """
        if not self.is_available:
            return {
                'success': False,
                'error': 'Supabase Storage servisi kullanılamıyor'
            }
        
        try:
            # Dosya adını oluştur
            file_extension = file.name.split('.')[-1] if '.' in file.name else 'jpg'
            file_name = f"bikes/{bike_id}/image_{bike_id}_{os.urandom(4).hex()}.{file_extension}"
            
            # Dosyayı güvenli şekilde oku
            file_content = self._read_file_safely(file)
            
            # Dosya içeriğinin bytes olduğunu tekrar kontrol et
            if not isinstance(file_content, bytes):
                logger.error(f"❌ Dosya içeriği bytes değil: {type(file_content)}")
                return {
                    'success': False,
                    'error': f'Dosya içeriği geçersiz tip: {type(file_content)}'
                }
            
            # Dosyayı yükle
            try:
                # Content type'ı güvenli şekilde al
                content_type = get_safe_content_type(file)
                
                # Content type'ın string olduğunu kontrol et
                if not isinstance(content_type, str):
                    logger.error(f"❌ Content type string değil: {type(content_type)} = {content_type}")
                    content_type = 'image/jpeg'  # Varsayılan
                
                logger.info(f"📤 Bike upload başlıyor: {file_name}, content_type: {content_type}, file_size: {len(file_content)} bytes")
                
                result = self.client.storage.from_(self.bikes_bucket).upload(
                    file_name,
                    file_content,
                    file_options={
                        "content-type": content_type,
                        "upsert": True
                    }
                )
            except Exception as upload_error:
                logger.error(f"❌ Supabase bike upload API hatası: {upload_error}")
                return {
                    'success': False,
                    'error': f'Supabase bike upload hatası: {str(upload_error)}'
                }
            
            if result:
                # Public URL'i al
                public_url = self.client.storage.from_(self.bikes_bucket).get_public_url(file_name)
                
                logger.info(f"✅ Motosiklet resmi başarıyla yüklendi: {file_name}")
                return {
                    'success': True,
                    'url': public_url,
                    'file_name': file_name
                }
            else:
                logger.error("❌ Supabase upload result boş")
                return {
                    'success': False,
                    'error': 'Dosya yükleme başarısız - result boş'
                }
                
        except Exception as e:
            logger.error(f"❌ Motosiklet resmi yükleme hatası: {e}")
            return {
                'success': False,
                'error': f'Dosya yükleme hatası: {str(e)}'
            }

    def delete_file(self, bucket: str, file_name: str) -> Dict[str, Any]:
        """
        Supabase Storage'dan dosya siler
        """
        if not self.is_available:
            return {
                'success': False,
                'error': 'Supabase Storage servisi kullanılamıyor'
            }
        
        try:
            result = self.client.storage.from_(bucket).remove([file_name])
            logger.info(f"✅ Dosya silindi: {bucket}/{file_name}")
            return {
                'success': True,
                'message': f'Dosya başarıyla silindi: {file_name}'
            }
        except Exception as e:
            logger.error(f"❌ Dosya silme hatası: {e}")
            return {
                'success': False,
                'error': f'Dosya silme hatası: {str(e)}'
            }

    def delete_multiple_files(self, bucket: str, file_names: list) -> Dict[str, Any]:
        """
        Supabase Storage'dan birden fazla dosya siler
        """
        if not self.is_available:
            return {
                'success': False,
                'error': 'Supabase Storage servisi kullanılamıyor'
            }
        
        try:
            result = self.client.storage.from_(bucket).remove(file_names)
            logger.info(f"✅ {len(file_names)} dosya silindi: {bucket}")
            return {
                'success': True,
                'message': f'{len(file_names)} dosya başarıyla silindi',
                'deleted_files': file_names
            }
        except Exception as e:
            logger.error(f"❌ Çoklu dosya silme hatası: {e}")
            return {
                'success': False,
                'error': f'Çoklu dosya silme hatası: {str(e)}'
            }

    def list_buckets(self) -> Dict[str, Any]:
        """
        Tüm bucket'ları listeler ve detaylarını döndürür
        """
        if not self.is_available:
            return {
                'success': False,
                'error': 'Supabase Storage servisi kullanılamıyor'
            }
        
        try:
            buckets = self.client.storage.list_buckets()
            bucket_details = []
            
            for bucket in buckets:
                bucket_info = {
                    'name': bucket.name,
                    'id': bucket.id,
                    'created_at': bucket.created_at,
                    'updated_at': bucket.updated_at,
                    'public': bucket.public if hasattr(bucket, 'public') else False,
                    'file_size_limit': bucket.file_size_limit if hasattr(bucket, 'file_size_limit') else None,
                    'allowed_mime_types': bucket.allowed_mime_types if hasattr(bucket, 'allowed_mime_types') else None
                }
                bucket_details.append(bucket_info)
            
            logger.info(f"📁 {len(bucket_details)} bucket listelendi")
            return {
                'success': True,
                'buckets': bucket_details,
                'total_buckets': len(bucket_details)
            }
        except Exception as e:
            logger.error(f"❌ Bucket listesi hatası: {e}")
            return {
                'success': False,
                'error': f'Bucket listesi hatası: {str(e)}'
            }

    def list_files_in_bucket(self, bucket_name: str, folder_path: str = None, limit: int = 100) -> Dict[str, Any]:
        """
        Belirtilen bucket'taki dosyaları listeler
        """
        if not self.is_available:
            return {
                'success': False,
                'error': 'Supabase Storage servisi kullanılamıyor'
            }
        
        try:
            # Dosyaları listele
            files = self.client.storage.from_(bucket_name).list(
                path=folder_path or '',
                limit=limit
            )
            
            file_details = []
            for file_info in files:
                file_detail = {
                    'name': file_info.get('name'),
                    'size': file_info.get('metadata', {}).get('size'),
                    'last_modified': file_info.get('updated_at'),
                    'content_type': file_info.get('metadata', {}).get('mimetype'),
                    'is_folder': file_info.get('metadata', {}).get('eTag') is None,  # Folder kontrolü
                    'path': file_info.get('name')
                }
                file_details.append(file_detail)
            
            logger.info(f"📄 {bucket_name} bucket'ında {len(file_details)} dosya listelendi")
            return {
                'success': True,
                'bucket': bucket_name,
                'folder': folder_path or 'root',
                'files': file_details,
                'total_files': len(file_details)
            }
        except Exception as e:
            logger.error(f"❌ Dosya listesi hatası: {e}")
            return {
                'success': False,
                'error': f'Dosya listesi hatası: {str(e)}'
            }

    def get_file_info(self, bucket_name: str, file_name: str) -> Dict[str, Any]:
        """
        Belirtilen dosya hakkında bilgi döndürür
        """
        if not self.is_available:
            return {
                'success': False,
                'error': 'Supabase Storage servisi kullanılamıyor'
            }
        
        try:
            # Dosya bilgilerini al
            file_info = self.client.storage.from_(bucket_name).list(
                path=file_name,
                limit=1
            )
            
            if not file_info:
                return {
                    'success': False,
                    'error': 'Dosya bulunamadı'
                }
            
            file_data = file_info[0]
            public_url = self.client.storage.from_(bucket_name).get_public_url(file_name)
            
            return {
                'success': True,
                'file_info': {
                    'name': file_data.get('name'),
                    'size': file_data.get('metadata', {}).get('size'),
                    'last_modified': file_data.get('updated_at'),
                    'content_type': file_data.get('metadata', {}).get('mimetype'),
                    'public_url': public_url,
                    'path': file_data.get('name')
                }
            }
        except Exception as e:
            logger.error(f"❌ Dosya bilgi hatası: {e}")
            return {
                'success': False,
                'error': f'Dosya bilgi hatası: {str(e)}'
            }

    def get_bucket_stats(self) -> Dict[str, Any]:
        """
        Tüm bucket'ların istatistiklerini döndürür
        """
        if not self.is_available:
            return {
                'success': False,
                'error': 'Supabase Storage servisi kullanılamıyor'
            }
        
        try:
            bucket_stats = {}
            all_buckets = [
                self.profile_bucket,
                self.events_bucket, 
                self.cover_bucket,
                self.groups_bucket,
                self.posts_bucket,
                self.bikes_bucket
            ]
            
            for bucket_name in all_buckets:
                try:
                    files = self.client.storage.from_(bucket_name).list(limit=1000)
                    bucket_stats[bucket_name] = {
                        'total_files': len(files),
                        'exists': True,
                        'files': [f.get('name') for f in files[:10]]  # İlk 10 dosya
                    }
                except Exception as bucket_error:
                    bucket_stats[bucket_name] = {
                        'total_files': 0,
                        'exists': False,
                        'error': str(bucket_error)
                    }
            
            return {
                'success': True,
                'bucket_stats': bucket_stats,
                'total_buckets': len(all_buckets)
            }
        except Exception as e:
            logger.error(f"❌ Bucket istatistik hatası: {e}")
            return {
                'success': False,
                'error': f'Bucket istatistik hatası: {str(e)}'
            }

    def test_connection(self) -> Dict[str, Any]:
        """
        Supabase bağlantısını test eder
        """
        if not self.is_available:
            return {
                'success': False,
                'error': 'Supabase Storage servisi kullanılamıyor'
            }
        
        try:
            # Bucket'ları listele
            buckets = self.client.storage.list_buckets()
            bucket_names = [bucket.name for bucket in buckets]
            
            return {
                'success': True,
                'buckets': bucket_names,
                'profile_bucket_exists': self.profile_bucket in bucket_names,
                'events_bucket_exists': self.events_bucket in bucket_names,
                'cover_bucket_exists': self.cover_bucket in bucket_names,
                'groups_bucket_exists': self.groups_bucket in bucket_names,
                'posts_bucket_exists': self.posts_bucket in bucket_names,
                'bikes_bucket_exists': self.bikes_bucket in bucket_names
            }
        except Exception as e:
            logger.error(f"❌ Supabase bağlantı test hatası: {e}")
            return {
                'success': False,
                'error': f'Bağlantı test hatası: {str(e)}'
            }
