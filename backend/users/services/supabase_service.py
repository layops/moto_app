# users/services/supabase_service.py
import logging
from django.conf import settings
from supabase import create_client
import re
import os
import uuid

logger = logging.getLogger(__name__)

class SupabaseStorage:
    def __init__(self):
        self.supabase_url = settings.SUPABASE_URL
        self.supabase_key = settings.SUPABASE_SERVICE_KEY
        self.profile_bucket = settings.SUPABASE_BUCKET 
        self.cover_bucket = settings.SUPABASE_COVER_BUCKET # Yeni eklenen
        
        try:
            # Supabase istemcisi oluşturuluyor
            self.client = create_client(self.supabase_url, self.supabase_key)
            logger.info("Supabase istemcisi başarıyla oluşturuldu")

            # Gerekli kovaların varlığını kontrol et
            buckets = [b.name for b in self.client.storage.list_buckets()]
            if self.profile_bucket not in buckets:
                raise ValueError(f"Profil kovası bulunamadı: {self.profile_bucket}")
            if self.cover_bucket not in buckets:
                raise ValueError(f"Kapak kovası bulunamadı: {self.cover_bucket}")
            logger.info(f"Kovalar bulundu: {self.profile_bucket} ve {self.cover_bucket}")

        except Exception as e:
            logger.error(f"Supabase istemcisi veya kova oluşturulamadı: {str(e)}")
            raise

    def upload_profile_picture(self, file_obj, user_id):
        """
        Profil fotoğrafı yükler ve public URL döner.
        """
        try:
            file_extension = os.path.splitext(file_obj.name)[1]
            unique_filename = f"users/{user_id}/profile_{uuid.uuid4()}{file_extension}"
            
            allowed_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
            if file_obj.content_type not in allowed_types:
                raise ValueError("Geçersiz dosya formatı")
            
            self.client.storage.from_(self.profile_bucket).upload(
                unique_filename,
                file_obj.read(),
                {"content-type": file_obj.content_type}
            )
            
            url = f"{self.supabase_url}/storage/v1/object/public/{self.profile_bucket}/{unique_filename}"
            logger.info(f"Profil resmi başarıyla yüklendi: {url}")
            return url
            
        except Exception as e:
            logger.error(f"Profil resmi yükleme hatası: {str(e)}")
            raise

    def delete_profile_picture(self, image_url):
        """
        Profil fotoğrafını siler.
        """
        try:
            if f"/{self.profile_bucket}/" in image_url:
                file_path = image_url.split(f"/{self.profile_bucket}/")[-1]
                self.client.storage.from_(self.profile_bucket).remove([file_path])
                logger.info(f"Profil resmi silindi: {file_path}")
        except Exception as e:
            logger.warning(f"Profil resmi silinemedi: {str(e)}")

    def upload_cover_picture(self, file_obj, user_id):
        """
        Kapak fotoğrafı yükler ve public URL döner.
        """
        try:
            file_extension = os.path.splitext(file_obj.name)[1]
            unique_filename = f"users/{user_id}/cover_{uuid.uuid4()}{file_extension}"

            allowed_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
            if file_obj.content_type not in allowed_types:
                raise ValueError("Geçersiz dosya formatı")

            self.client.storage.from_(self.cover_bucket).upload(
                unique_filename,
                file_obj.read(),
                {"content-type": file_obj.content_type}
            )

            url = f"{self.supabase_url}/storage/v1/object/public/{self.cover_bucket}/{unique_filename}"
            logger.info(f"Kapak resmi başarıyla yüklendi: {url}")
            return url

        except Exception as e:
            logger.error(f"Kapak resmi yükleme hatası: {str(e)}")
            raise
    
    def delete_cover_picture(self, image_url):
        """
        Kapak fotoğrafını siler.
        """
        try:
            if f"/{self.cover_bucket}/" in image_url:
                file_path = image_url.split(f"/{self.cover_bucket}/")[-1]
                self.client.storage.from_(self.cover_bucket).remove([file_path])
                logger.info(f"Kapak resmi silindi: {file_path}")
        except Exception as e:
            logger.warning(f"Kapak resmi silinemedi: {str(e)}")
    
        def upload_event_picture(self, file_obj, event_id):
        """
        Etkinlik resmi yükler ve public URL döner.
        """
        try:
            file_extension = os.path.splitext(file_obj.name)[1]
            unique_filename = f"events/{event_id}/event_{uuid.uuid4()}{file_extension}"

            allowed_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
            if file_obj.content_type not in allowed_types:
                raise ValueError("Geçersiz dosya formatı")

            # Burada event_pictures bucket’ını kullanıyoruz
            self.client.storage.from_('event_pictures').upload(
                unique_filename,
                file_obj.read(),
                {"content-type": file_obj.content_type}
            )

            url = f"{self.supabase_url}/storage/v1/object/public/event_pictures/{unique_filename}"
            logger.info(f"Etkinlik resmi başarıyla yüklendi: {url}")
            return url

        except Exception as e:
            logger.error(f"Etkinlik resmi yükleme hatası: {str(e)}")
            raise

    def delete_event_picture(self, image_url):
        """
        Etkinlik resmini siler.
        """
        try:
            if "/event_pictures/" in image_url:
                file_path = image_url.split("/event_pictures/")[-1]
                self.client.storage.from_('event_pictures').remove([file_path])
                logger.info(f"Etkinlik resmi silindi: {file_path}")
        except Exception as e:
            logger.warning(f"Etkinlik resmi silinemedi: {str(e)}")