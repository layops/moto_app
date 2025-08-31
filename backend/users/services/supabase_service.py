# users/services/supabase_service.py
import logging
from django.conf import settings
from supabase import create_client, Client
import re

logger = logging.getLogger(__name__)

class SupabaseStorage:
    def __init__(self):
        self.supabase_url = settings.SUPABASE_URL
        self.supabase_key = settings.SUPABASE_SERVICE_KEY
        self.bucket = settings.SUPABASE_BUCKET
        
        try:
            self.client: Client = create_client(self.supabase_url, self.supabase_key)
            logger.info("Supabase istemcisi başarıyla oluşturuldu")
        except Exception as e:
            logger.error(f"Supabase istemcisi oluşturulamadı: {str(e)}")
            raise

    def upload_profile_picture(self, file, user_id):
        """
        Profil fotoğrafı yükler ve public URL döner.
        """
        try:
            # Dosya adını güvenli hale getir
            original_name = file.name
            safe_name = re.sub(r'[^a-zA-Z0-9_.-]', '_', original_name)
            file_path = f"users/{user_id}/profile_{safe_name}"
            
            # Dosya boyutu kontrolü (5MB sınırı)
            if file.size > 5 * 1024 * 1024:
                raise ValueError("Dosya boyutu 5MB'ı aşamaz")
            
            # Dosya tipi kontrolü
            allowed_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
            if file.content_type not in allowed_types:
                raise ValueError("Geçersiz dosya formatı")
            
            # Dosyayı byte olarak oku
            file_content = file.read()
            
            # Supabase'e yükle
            response = self.client.storage.from_(self.bucket).upload(
                file_path, 
                file_content, 
                {"content-type": file.content_type}
            )
            
            # Public URL oluştur
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
            # URL'den dosya yolunu çıkar
            if f"/{self.bucket}/" in image_url:
                file_path = image_url.split(f"/{self.bucket}/")[-1]
                
                # Dosyayı sil
                self.client.storage.from_(self.bucket).remove([file_path])
                logger.info(f"Profil resmi silindi: {file_path}")
            
        except Exception as e:
            logger.warning(f"Profil resmi silinemedi: {str(e)}")
            # Silme hatası kritik değil, devam et