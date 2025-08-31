# users/services/supabase_service.py
import logging
from django.conf import settings
from supabase import create_client
import re

logger = logging.getLogger(__name__)

class SupabaseStorage:
    def __init__(self):
        self.supabase_url = settings.SUPABASE_URL
        self.supabase_key = settings.SUPABASE_SERVICE_KEY
        self.bucket = settings.SUPABASE_BUCKET

        try:
            # Proxy parametresi kaldırıldı
            self.client = create_client(self.supabase_url, self.supabase_key)
            logger.info("Supabase istemcisi başarıyla oluşturuldu")

            # Bucket var mı kontrol et, yoksa hata ver
            buckets = [b['name'] for b in self.client.storage.list_buckets()]
            if self.bucket not in buckets:
                raise ValueError(f"Bucket bulunamadı: {self.bucket}")
                
        except Exception as e:
            logger.error(f"Supabase istemcisi oluşturulamadı: {str(e)}")
            raise

    def upload_profile_picture(self, file, user_id):
        """
        Profil fotoğrafı yükler ve public URL döner.
        """
        try:
            original_name = file.name
            safe_name = re.sub(r'[^a-zA-Z0-9_.-]', '_', original_name)
            file_path = f"users/{user_id}/profile_{safe_name}"

            if file.size > 5 * 1024 * 1024:
                raise ValueError("Dosya boyutu 5MB'ı aşamaz")
            
            allowed_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
            if file.content_type not in allowed_types:
                raise ValueError("Geçersiz dosya formatı")
            
            file_content = file.read()
            self.client.storage.from_(self.bucket).upload(
                file_path, 
                file_content, 
                {"content-type": file.content_type}
            )
            
            url = f"{self.supabase_url}/storage/v1/object/public/{self.bucket}/{file_path}"
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
            if f"/{self.bucket}/" in image_url:
                file_path = image_url.split(f"/{self.bucket}/")[-1]
                self.client.storage.from_(self.bucket).remove([file_path])
                logger.info(f"Profil resmi silindi: {file_path}")
        except Exception as e:
            logger.warning(f"Profil resmi silinemedi: {str(e)}")
