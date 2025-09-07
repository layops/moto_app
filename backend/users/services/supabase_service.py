# users/services/supabase_service.py
import logging
from django.conf import settings
from supabase import create_client
import os
import uuid

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
        
        try:
            self.client = create_client(self.supabase_url, self.supabase_key)
            logger.info("Supabase istemcisi başarıyla oluşturuldu")

            buckets = [b.name for b in self.client.storage.list_buckets()]
            for bucket in [self.profile_bucket, self.cover_bucket, self.events_bucket, self.groups_bucket, self.posts_bucket]:
                if bucket not in buckets:
                    raise ValueError(f"Kova bulunamadı: {bucket}")
            logger.info(f"Kovalar bulundu: {self.profile_bucket}, {self.cover_bucket}, {self.events_bucket}, {self.groups_bucket}, {self.posts_bucket}")

        except Exception as e:
            logger.error(f"Supabase istemcisi veya kova oluşturulamadı: {str(e)}")
            raise

    # Profil resimleri
    def upload_profile_picture(self, file_obj, user_id):
        return self._upload_file(file_obj, self.profile_bucket, f"users/{user_id}/profile_")
    
    def delete_profile_picture(self, image_url):
        self._delete_file(image_url, self.profile_bucket)

    # Kapak resimleri
    def upload_cover_picture(self, file_obj, user_id):
        return self._upload_file(file_obj, self.cover_bucket, f"users/{user_id}/cover_")
    
    def delete_cover_picture(self, image_url):
        self._delete_file(image_url, self.cover_bucket)

    # Event resimleri
    def upload_event_picture(self, file_obj, event_id):
        return self._upload_file(file_obj, self.events_bucket, f"events/{event_id}/cover_")
    
    def delete_event_picture(self, image_url):
        self._delete_file(image_url, self.events_bucket)

    # Grup profil resimleri
    def upload_group_profile_picture(self, file_obj, group_id):
        return self._upload_file(file_obj, self.groups_bucket, f"groups/{group_id}/profile_")
    
    def delete_group_profile_picture(self, image_url):
        self._delete_file(image_url, self.groups_bucket)

    # Grup post resimleri
    def upload_group_post_image(self, file_obj, group_id, post_id):
        if group_id is None:
            # Genel post için
            return self._upload_file(file_obj, self.posts_bucket, f"general/posts/{post_id}/")
        else:
            # Grup post için
            return self._upload_file(file_obj, self.posts_bucket, f"groups/{group_id}/posts/{post_id}/")
    
    def delete_group_post_image(self, image_url):
        self._delete_file(image_url, self.posts_bucket)

    # Ortak fonksiyonlar
    def _upload_file(self, file_obj, bucket, prefix):
        try:
            file_extension = os.path.splitext(file_obj.name)[1]
            unique_filename = f"{prefix}{uuid.uuid4()}{file_extension}"
            
            allowed_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
            if file_obj.content_type not in allowed_types:
                raise ValueError("Geçersiz dosya formatı")
            
            self.client.storage.from_(bucket).upload(
                unique_filename,
                file_obj.read(),
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

    def upload_group_message_media(self, media_file, group_id, message_id):
        """Grup mesaj medyasını Supabase'e yükle"""
        try:
            # Dosya uzantısını al
            file_extension = media_file.name.split('.')[-1].lower()
            
            # Dosya adını oluştur - grup mesajları için ayrı klasör yapısı
            file_name = f"messages/group_{group_id}/message_{message_id}_{uuid.uuid4()}.{file_extension}"
            
            # Dosya boyutunu kontrol et
            media_file.seek(0, 2)  # Dosyanın sonuna git
            file_size = media_file.tell()  # Dosya boyutunu al
            media_file.seek(0)  # Dosyanın başına dön
            
            logger.info(f"Dosya boyutu: {file_size} bytes")
            
            if file_size == 0:
                raise Exception("Dosya boş")
            
            # Dosyayı yükle - mevcut group_posts_images bucket'ını kullan
            result = self.client.storage.from_('group_posts_images').upload(
                file_name,
                media_file,
                file_options={
                    "content-type": media_file.content_type,
                    "upsert": True  # Aynı isimde dosya varsa üzerine yaz
                }
            )
            
            logger.info(f"Upload result: {result}")
            
            if result:
                # Public URL'i al
                public_url = self.client.storage.from_('group_posts_images').get_public_url(file_name)
                logger.info(f"Grup mesaj medyası yüklendi: {public_url}")
                return public_url
            else:
                raise Exception("Dosya yükleme başarısız")
                
        except Exception as e:
            logger.error(f"Grup mesaj medyası yükleme hatası: {str(e)}")
            raise e

    def delete_group_message_media(self, media_url):
        """Grup mesaj medyasını Supabase'den sil"""
        try:
            bucket = 'group_posts_images'
            if f"/{bucket}/" in media_url:
                file_path = media_url.split(f"/{bucket}/")[-1]
                self.client.storage.from_(bucket).remove([file_path])
                logger.info(f"Grup mesaj medyası silindi: {file_path}")
        except Exception as e:
            logger.warning(f"Grup mesaj medyası silinemedi: {str(e)}")