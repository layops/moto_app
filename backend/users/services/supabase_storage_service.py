import os
import logging
from typing import Dict, Any, Optional
from supabase import Client, create_client

logger = logging.getLogger(__name__)

class SupabaseStorageService:
    def __init__(self):
        self.client: Optional[Client] = None
        self.profile_bucket = "profile-pictures"
        self.events_bucket = "event-pictures"
        self.is_available = False
        
        try:
            # Supabase konfigürasyonu
            supabase_url = os.getenv('SUPABASE_URL')
            supabase_key = os.getenv('SUPABASE_ANON_KEY')
            
            if supabase_url and supabase_key:
                self.client = create_client(supabase_url, supabase_key)
                self.is_available = True
                logger.info("Supabase Storage servisi başlatıldı")
            else:
                logger.warning("Supabase konfigürasyonu bulunamadı")
                
        except Exception as e:
            logger.error(f"Supabase Storage servisi başlatılamadı: {e}")
            self.is_available = False

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
            
            # Dosyayı yükle
            result = self.client.storage.from_(self.events_bucket).upload(
                file_name,
                file.read(),
                file_options={
                    "content-type": file.content_type,
                    "upsert": True
                }
            )
            
            if result:
                # Public URL'i al
                public_url = self.client.storage.from_(self.events_bucket).get_public_url(file_name)
                
                logger.info(f"Event resmi başarıyla yüklendi: {file_name}")
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
            logger.error(f"Event resmi yükleme hatası: {e}")
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
            result = self.client.storage.from_(self.profile_bucket).upload(
                file_name,
                file.read(),
                file_options={
                    "content-type": file.content_type,
                    "upsert": True
                }
            )
            
            if result:
                # Public URL'i al
                public_url = self.client.storage.from_(self.profile_bucket).get_public_url(file_name)
                
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
