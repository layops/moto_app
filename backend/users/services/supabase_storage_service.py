"""
Supabase Storage Service
Güvenli ve basit dosya yükleme servisi
"""
import os
import logging
from typing import Dict, Any, Optional
from supabase import Client, create_client
from django.conf import settings

logger = logging.getLogger(__name__)

def get_safe_content_type(file) -> str:
    """Django file object'inden güvenli content_type alır"""
    content_type = getattr(file, 'content_type', None)

    if not content_type or isinstance(content_type, bool):
        file_name = getattr(file, 'name', '')
        ext = file_name.lower().split('.')[-1] if '.' in file_name else ''
        mapping = {
            'jpg': 'image/jpeg',
            'jpeg': 'image/jpeg',
            'png': 'image/png',
            'gif': 'image/gif',
            'webp': 'image/webp'
        }
        return mapping.get(ext, 'application/octet-stream')
    return content_type

class SupabaseStorageService:
    def __init__(self):
        self.client: Optional[Client] = None
        self.is_available = False

        self.buckets = {
            'profile': 'profile_pictures',
            'cover': 'cover_pictures',
            'events': 'events_pictures',
            'groups': 'groups_profile_pictures',
            'posts': 'group_posts_images',
            'bikes': 'bikes_images'
        }

        self._initialize_client()

    def _initialize_client(self):
        """Supabase client'ını başlat"""
        try:
            supabase_url = os.getenv('SUPABASE_URL') or getattr(settings, 'SUPABASE_URL', None)
            supabase_key = (os.getenv('SUPABASE_SERVICE_ROLE_KEY') or 
                            getattr(settings, 'SUPABASE_SERVICE_ROLE_KEY', None) or
                            os.getenv('SUPABASE_ANON_KEY') or 
                            getattr(settings, 'SUPABASE_ANON_KEY', None))

            if supabase_url and supabase_key:
                self.client = create_client(supabase_url, supabase_key)
                self.is_available = True
                logger.info("✅ Supabase Storage servisi başlatıldı")
            else:
                logger.warning("❌ Supabase konfigürasyonu bulunamadı")
        except Exception as e:
            logger.error(f"❌ Supabase başlatılamadı: {e}")

    def _read_file_as_bytes(self, file) -> bytes:
        """Dosyayı güvenli şekilde oku ve bytes olarak döndür"""
        try:
            if hasattr(file, 'seek'):
                file.seek(0)

            if hasattr(file, 'chunks'):
                content = b''.join(chunk for chunk in file.chunks() if isinstance(chunk, bytes))
                if not content:
                    raise ValueError("Dosya boş veya okunamadı (chunks)")
                return content
            elif hasattr(file, 'read'):
                content = file.read()
                if isinstance(content, bytes):
                    return content
                raise ValueError("Dosya içeriği bytes değil")
            raise ValueError("Dosya okunamıyor")
        except Exception as e:
            logger.error(f"❌ Dosya okuma hatası: {e}")
            raise

    def upload_file(self, file, bucket_type: str, file_path: str, content_type: str = None) -> Dict[str, Any]:
        """Generic dosya yükleme fonksiyonu"""
        if not self.is_available:
            return {'success': False, 'error': 'Supabase servisi kullanılamıyor'}
        if bucket_type not in self.buckets:
            return {'success': False, 'error': f'Geçersiz bucket tipi: {bucket_type}'}

        try:
            file_content = self._read_file_as_bytes(file)
            content_type = content_type or get_safe_content_type(file)
            bucket_name = self.buckets[bucket_type]

            logger.info(f"📤 Upload: {file_path} -> {bucket_name}")

            resp = self.client.storage.from_(bucket_name).upload(
                file_path,
                file_content,
                {"content-type": content_type, "upsert": True}
            )

            if resp.get('error'):
                raise Exception(resp['error'])

            public_url = self.client.storage.from_(bucket_name).get_public_url(file_path).get('public_url')
            logger.info(f"✅ Dosya yüklendi: {file_path}")
            return {'success': True, 'url': public_url, 'file_name': file_path}

        except Exception as e:
            logger.error(f"❌ Upload hatası: {e}")
            return {'success': False, 'error': f'Upload hatası: {str(e)}'}

    # Convenience methods
    def upload_profile_picture(self, file, username: str) -> Dict[str, Any]:
        ext = file.name.split('.')[-1] if '.' in file.name else 'jpg'
        path = f"{username}/profile_{username}_{os.urandom(4).hex()}.{ext}"
        return self.upload_file(file, 'profile', path)

    def upload_cover_picture(self, file, username: str) -> Dict[str, Any]:
        ext = file.name.split('.')[-1] if '.' in file.name else 'jpg'
        path = f"{username}/cover_{username}_{os.urandom(4).hex()}.{ext}"
        return self.upload_file(file, 'cover', path)

    def upload_event_picture(self, file, event_id: str) -> Dict[str, Any]:
        ext = file.name.split('.')[-1] if '.' in file.name else 'jpg'
        path = f"events/{event_id}/cover_{event_id}_{os.urandom(4).hex()}.{ext}"
        return self.upload_file(file, 'events', path)

    def upload_group_picture(self, file, group_id: str) -> Dict[str, Any]:
        ext = file.name.split('.')[-1] if '.' in file.name else 'jpg'
        path = f"groups/{group_id}/profile_{group_id}_{os.urandom(4).hex()}.{ext}"
        return self.upload_file(file, 'groups', path)

    def upload_post_image(self, file, post_id: str) -> Dict[str, Any]:
        ext = file.name.split('.')[-1] if '.' in file.name else 'jpg'
        path = f"posts/{post_id}/image_{post_id}_{os.urandom(4).hex()}.{ext}"
        return self.upload_file(file, 'posts', path)

    def upload_bike_image(self, file, bike_id: str) -> Dict[str, Any]:
        ext = file.name.split('.')[-1] if '.' in file.name else 'jpg'
        path = f"bikes/{bike_id}/image_{bike_id}_{os.urandom(4).hex()}.{ext}"
        return self.upload_file(file, 'bikes', path)
