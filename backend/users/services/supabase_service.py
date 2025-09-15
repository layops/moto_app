# users/services/supabase_service.py
import logging
from django.conf import settings

# Supabase import'u daha detaylı hata kontrolü ile
SUPABASE_AVAILABLE = False
create_client = None
import_error = None

try:
    from supabase import create_client
    SUPABASE_AVAILABLE = True
    logging.getLogger(__name__).info("Supabase modülü başarıyla yüklendi")
except ImportError as e:
    import_error = str(e)
    logging.getLogger(__name__).warning(f"Supabase modülü yüklenemedi: {import_error}")
except Exception as e:
    import_error = str(e)
    logging.getLogger(__name__).error(f"Supabase modülü yüklenirken beklenmeyen hata: {import_error}")
import os
import uuid
import re

logger = logging.getLogger(__name__)

class SupabaseStorage:
    def __init__(self):
        self.supabase_url = settings.SUPABASE_URL
        self.supabase_key = settings.SUPABASE_SERVICE_KEY
        self.profile_bucket = settings.SUPABASE_BUCKET
        self.cover_bucket = settings.SUPABASE_COVER_BUCKET
        self.events_bucket = getattr(settings, 'SUPABASE_EVENTS_BUCKET', 'events_pictures')
        self.groups_bucket = getattr(settings, 'SUPABASE_GROUPS_BUCKET', 'groups_profile_pictures')
        self.posts_bucket = getattr(settings, 'SUPABASE_POSTS_BUCKET', 'group_posts_images')
        
        # Supabase kullanımını kontrol et
        self.use_supabase = getattr(settings, 'USE_SUPABASE_STORAGE', False)
        self.client = None
        self.is_available = False
        
        try:
            # Supabase modülü ve service key kontrolü
            if not SUPABASE_AVAILABLE:
                if import_error:
                    logger.warning(f"Supabase modülü bulunamadı: {import_error}")
                else:
                    logger.warning("Supabase modülü bulunamadı, istemci oluşturulamadı")
                return
                
            if not self.supabase_key:
                logger.warning("SUPABASE_SERVICE_KEY bulunamadı, Supabase devre dışı")
                return
                
            if not self.use_supabase:
                logger.info("Supabase storage devre dışı (USE_SUPABASE_STORAGE=false)")
                return
            
            # Supabase client oluştur - CLIENT_CLASS parametresi olmadan
            self.client = create_client(self.supabase_url, self.supabase_key)
            logger.info("Supabase istemcisi başarıyla oluşturuldu")
            
            # Bucket'ları kontrol et
            if self.client:
                buckets = [b.name for b in self.client.storage.list_buckets()]
                required_buckets = [self.profile_bucket, self.cover_bucket, self.events_bucket, self.groups_bucket, self.posts_bucket]
                
                missing_buckets = [bucket for bucket in required_buckets if bucket not in buckets]
                if missing_buckets:
                    logger.warning(f"Eksik bucket'lar: {missing_buckets}")
                    # Kritik bucket'lar eksikse Supabase'i devre dışı bırak
                    if self.profile_bucket in missing_buckets:
                        logger.error("Profil bucket'ı eksik, Supabase devre dışı")
                        self.client = None
                        return
                else:
                    logger.info(f"Tüm bucket'lar mevcut: {required_buckets}")
                    self.is_available = True

        except Exception as e:
            logger.error(f"Supabase istemcisi oluşturulamadı: {str(e)}")
            logger.error(f"Hata türü: {type(e).__name__}")
            self.client = None
            self.is_available = False

    def _is_available(self):
        """Supabase'in kullanılabilir olup olmadığını kontrol et"""
        return self.is_available and self.client is not None

    def _sanitize_filename(self, filename):
        """Dosya adını güvenli hale getir"""
        # Tehlikeli karakterleri temizle
        filename = re.sub(r'[^\w\-_\.]', '_', filename)
        # Çoklu alt çizgileri tek alt çizgiye çevir
        filename = re.sub(r'_+', '_', filename)
        # Başında ve sonunda alt çizgi varsa temizle
        filename = filename.strip('_')
        return filename

    def _fallback_upload(self, file_obj, bucket, prefix):
        """Supabase kullanılamadığında local storage'a fallback"""
        try:
            # Dosya boyutunu kontrol et
            file_obj.seek(0, 2)  # Dosyanın sonuna git
            file_size = file_obj.tell()  # Dosya boyutunu al
            file_obj.seek(0)  # Dosyanın başına dön
            
            if file_size == 0:
                raise Exception("Dosya boş")
            
            # Dosya boyutu kontrolü (5MB limit)
            max_size = 5 * 1024 * 1024  # 5MB
            if file_size > max_size:
                raise ValueError(f"Dosya boyutu çok büyük. Maksimum {max_size // (1024*1024)}MB olmalı")
            
            # Dosya türü kontrolü
            allowed_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
            if file_obj.content_type not in allowed_types:
                raise ValueError("Geçersiz dosya formatı")
            
            # Local media klasörüne kaydet
            media_root = settings.MEDIA_ROOT
            bucket_dir = media_root / bucket
            bucket_dir.mkdir(parents=True, exist_ok=True)
            
            # Dosya adını güvenli hale getir
            safe_filename = self._sanitize_filename(file_obj.name)
            file_extension = os.path.splitext(safe_filename)[1]
            unique_filename = f"{prefix}{uuid.uuid4()}{file_extension}"
            file_path = bucket_dir / unique_filename
            
            with open(file_path, 'wb') as f:
                for chunk in file_obj.chunks():
                    f.write(chunk)
            
            # Public URL oluştur
            url = f"{settings.BASE_URL}{settings.MEDIA_URL}{bucket}/{unique_filename}"
            logger.info(f"Dosya local storage'a kaydedildi: {url}")
            return url
            
        except Exception as e:
            logger.error(f"Local storage fallback hatası: {str(e)}")
            raise

    # Profil resimleri
    def upload_profile_picture(self, file_obj, user_id):
        if self._is_available():
            return self._upload_file(file_obj, self.profile_bucket, f"users/{user_id}/profile_")
        else:
            return self._fallback_upload(file_obj, self.profile_bucket, f"users/{user_id}/profile_")
    
    def delete_profile_picture(self, image_url):
        if self._is_available():
            self._delete_file(image_url, self.profile_bucket)
        else:
            self._fallback_delete(image_url)

    # Kapak resimleri
    def upload_cover_picture(self, file_obj, user_id):
        if self._is_available():
            return self._upload_file(file_obj, self.cover_bucket, f"users/{user_id}/cover_")
        else:
            return self._fallback_upload(file_obj, self.cover_bucket, f"users/{user_id}/cover_")
    
    def delete_cover_picture(self, image_url):
        if self._is_available():
            self._delete_file(image_url, self.cover_bucket)
        else:
            self._fallback_delete(image_url)

    # Event resimleri
    def upload_event_picture(self, file_obj, event_id):
        if self._is_available():
            return self._upload_file(file_obj, self.events_bucket, f"events/{event_id}/cover_")
        else:
            return self._fallback_upload(file_obj, self.events_bucket, f"events/{event_id}/cover_")
    
    def delete_event_picture(self, image_url):
        if self._is_available():
            self._delete_file(image_url, self.events_bucket)
        else:
            self._fallback_delete(image_url)

    # Grup profil resimleri
    def upload_group_profile_picture(self, file_obj, group_id):
        if self._is_available():
            return self._upload_file(file_obj, self.groups_bucket, f"groups/{group_id}/profile_")
        else:
            return self._fallback_upload(file_obj, self.groups_bucket, f"groups/{group_id}/profile_")
    
    def delete_group_profile_picture(self, image_url):
        if self._is_available():
            self._delete_file(image_url, self.groups_bucket)
        else:
            self._fallback_delete(image_url)

    # Grup post resimleri
    def upload_group_post_image(self, file_obj, group_id, post_id):
        if group_id is None:
            # Genel post için
            prefix = f"general/posts/{post_id}/"
        else:
            # Grup post için
            prefix = f"groups/{group_id}/posts/{post_id}/"
            
        if self._is_available():
            return self._upload_file(file_obj, self.posts_bucket, prefix)
        else:
            return self._fallback_upload(file_obj, self.posts_bucket, prefix)
    
    def delete_group_post_image(self, image_url):
        if self._is_available():
            self._delete_file(image_url, self.posts_bucket)
        else:
            self._fallback_delete(image_url)

    # Ortak fonksiyonlar
    def _upload_file(self, file_obj, bucket, prefix):
        try:
            # Dosya adını güvenli hale getir
            safe_filename = self._sanitize_filename(file_obj.name)
            file_extension = os.path.splitext(safe_filename)[1]
            unique_filename = f"{prefix}{uuid.uuid4()}{file_extension}"
            
            # Dosya boyutunu kontrol et
            file_obj.seek(0, 2)  # Dosyanın sonuna git
            file_size = file_obj.tell()  # Dosya boyutunu al
            file_obj.seek(0)  # Dosyanın başına dön
            
            logger.info(f"Upload dosya boyutu: {file_size} bytes")
            logger.info(f"Upload dosya adı: {file_obj.name}")
            logger.info(f"Upload content type: {file_obj.content_type}")
            
            if file_size == 0:
                raise Exception("Dosya boş")
            
            # Dosya boyutu kontrolü (5MB limit)
            max_size = 5 * 1024 * 1024  # 5MB
            if file_size > max_size:
                raise ValueError(f"Dosya boyutu çok büyük. Maksimum {max_size // (1024*1024)}MB olmalı")
            
            allowed_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
            if file_obj.content_type not in allowed_types:
                raise ValueError("Geçersiz dosya formatı")
            
            # Dosyayı tekrar oku (seek(0) sonrası)
            file_data = file_obj.read()
            self.client.storage.from_(bucket).upload(
                unique_filename,
                file_data,
                {"content-type": file_obj.content_type}
            )
            
            url = f"{self.supabase_url}/storage/v1/object/public/{bucket}/{unique_filename}"
            logger.info(f"Dosya başarıyla yüklendi: {url}")
            return url

        except Exception as e:
            logger.error(f"Dosya yükleme hatası: {str(e)}")
            raise

    def _delete_file(self, image_url, bucket):
        try:
            if f"/{bucket}/" in image_url:
                file_path = image_url.split(f"/{bucket}/")[-1]
                self.client.storage.from_(bucket).remove([file_path])
                logger.info(f"Dosya silindi: {file_path}")
        except Exception as e:
            logger.warning(f"Dosya silinemedi: {str(e)}")

    def _fallback_delete(self, image_url):
        """Local storage'dan dosya silme"""
        try:
            if settings.MEDIA_URL in image_url:
                file_path = image_url.split(settings.MEDIA_URL)[-1]
                full_path = settings.MEDIA_ROOT / file_path
                if full_path.exists():
                    full_path.unlink()
                    logger.info(f"Local dosya silindi: {file_path}")
        except Exception as e:
            logger.warning(f"Local dosya silinemedi: {str(e)}")

    def upload_group_message_media(self, media_file, group_id, message_id):
        """Grup mesaj medyasını yükle"""
        try:
            # Dosya adını güvenli hale getir
            safe_filename = self._sanitize_filename(media_file.name)
            file_extension = os.path.splitext(safe_filename)[1]
            
            # Dosya adını oluştur - grup mesajları için ayrı klasör yapısı
            unique_filename = f"messages/group_{group_id}/message_{message_id}_{uuid.uuid4()}{file_extension}"
            
            # Dosya boyutunu kontrol et
            media_file.seek(0, 2)  # Dosyanın sonuna git
            file_size = media_file.tell()  # Dosya boyutunu al
            media_file.seek(0)  # Dosyanın başına dön
            
            logger.info(f"Dosya boyutu: {file_size} bytes")
            logger.info(f"Dosya adı: {media_file.name}")
            logger.info(f"Content type: {media_file.content_type}")
            logger.info(f"Unique filename: {unique_filename}")
            
            if file_size == 0:
                raise Exception("Dosya boş")
            
            # Dosya boyutu kontrolü (5MB limit)
            max_size = 5 * 1024 * 1024  # 5MB
            if file_size > max_size:
                raise ValueError(f"Dosya boyutu çok büyük. Maksimum {max_size // (1024*1024)}MB olmalı")
            
            # Dosya türü kontrolü
            allowed_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
            if media_file.content_type not in allowed_types:
                raise ValueError("Geçersiz dosya formatı")
            
            if self._is_available():
                # Dosyayı tekrar oku (seek(0) sonrası)
                file_data = media_file.read()
                # Supabase'e yükle
                self.client.storage.from_(self.groups_bucket).upload(
                    unique_filename,
                    file_data,
                    {"content-type": media_file.content_type}
                )
                
                # Public URL'i oluştur
                public_url = f"{self.supabase_url}/storage/v1/object/public/{self.groups_bucket}/{unique_filename}"
                logger.info(f"Grup mesaj medyası Supabase'e yüklendi: {public_url}")
                return public_url
            else:
                # Local storage'a yükle
                return self._fallback_upload(media_file, self.groups_bucket, f"messages/group_{group_id}/message_{message_id}_")
                
        except Exception as e:
            logger.error(f"Grup mesaj medyası yükleme hatası: {str(e)}")
            raise e

    def delete_group_message_media(self, media_url):
        """Grup mesaj medyasını sil"""
        if self._is_available():
            bucket = self.groups_bucket
            if f"/{bucket}/" in media_url:
                file_path = media_url.split(f"/{bucket}/")[-1]
                self.client.storage.from_(bucket).remove([file_path])
                logger.info(f"Grup mesaj medyası Supabase'den silindi: {file_path}")
        else:
            self._fallback_delete(media_url)