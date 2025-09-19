"""
Supabase Storage Service
Güvenli ve basit dosya yükleme servisi
"""
import os
import logging
import time
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

    def upload_file(self, file, bucket_type: str, file_path: str, content_type: str = None, max_retries: int = 3) -> Dict[str, Any]:
        """Generic dosya yükleme fonksiyonu - retry mekanizması ile"""
        if not self.is_available:
            return {'success': False, 'error': 'Supabase servisi kullanılamıyor'}
        if bucket_type not in self.buckets:
            return {'success': False, 'error': f'Geçersiz bucket tipi: {bucket_type}'}

        last_error = None
        
        for attempt in range(max_retries):
            try:
                file_content = self._read_file_as_bytes(file)
                content_type = content_type or get_safe_content_type(file)
                bucket_name = self.buckets[bucket_type]

                logger.info(f"📤 Upload (attempt {attempt + 1}/{max_retries}): {file_path} -> {bucket_name}")

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
                last_error = e
                logger.warning(f"⚠️ Upload attempt {attempt + 1} failed: {e}")
                
                if attempt < max_retries - 1:
                    wait_time = 2 ** attempt  # Exponential backoff
                    logger.info(f"⏳ Retrying in {wait_time} seconds...")
                    time.sleep(wait_time)
                else:
                    logger.error(f"❌ Upload failed after {max_retries} attempts: {e}")
        
        return {'success': False, 'error': f'Upload hatası (after {max_retries} attempts): {str(last_error)}'}

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

    def delete_file(self, bucket_name: str, file_path: str) -> Dict[str, Any]:
        """Dosyayı Supabase Storage'dan sil"""
        if not self.is_available:
            return {'success': False, 'error': 'Supabase servisi kullanılamıyor'}
        
        try:
            logger.info(f"🗑️ Delete: {file_path} from {bucket_name}")
            
            resp = self.client.storage.from_(bucket_name).remove([file_path])
            
            if resp.get('error'):
                raise Exception(resp['error'])
            
            logger.info(f"✅ Dosya silindi: {file_path}")
            return {'success': True, 'message': f'Dosya başarıyla silindi: {file_path}'}
            
        except Exception as e:
            logger.error(f"❌ Delete hatası: {e}")
            return {'success': False, 'error': f'Delete hatası: {str(e)}'}

    def test_connection(self) -> Dict[str, Any]:
        """Supabase Storage bağlantısını test et"""
        if not self.is_available:
            return {'success': False, 'error': 'Supabase servisi kullanılamıyor'}
        
        try:
            # Bucket'ları kontrol et
            bucket_status = {}
            existing_buckets = []
            
            for bucket_type, bucket_name in self.buckets.items():
                try:
                    # Bucket'ın varlığını kontrol et
                    resp = self.client.storage.list_buckets()
                    bucket_exists = any(bucket['name'] == bucket_name for bucket in resp)
                    bucket_status[f'{bucket_type}_bucket_exists'] = bucket_exists
                    
                    if bucket_exists:
                        existing_buckets.append(bucket_name)
                        
                except Exception as e:
                    bucket_status[f'{bucket_type}_bucket_exists'] = False
                    logger.warning(f"Bucket kontrol hatası {bucket_name}: {e}")
            
            return {
                'success': True,
                'buckets': existing_buckets,
                'profile_bucket_exists': bucket_status.get('profile_bucket_exists', False),
                'events_bucket_exists': bucket_status.get('events_bucket_exists', False),
                'cover_bucket_exists': bucket_status.get('cover_bucket_exists', False),
                'groups_bucket_exists': bucket_status.get('groups_bucket_exists', False),
                'posts_bucket_exists': bucket_status.get('posts_bucket_exists', False),
                'bikes_bucket_exists': bucket_status.get('bikes_bucket_exists', False)
            }
            
        except Exception as e:
            logger.error(f"❌ Connection test hatası: {e}")
            return {'success': False, 'error': f'Connection test hatası: {str(e)}'}

    # Bucket referansları (views.py'da kullanılıyor)
    @property
    def profile_bucket(self) -> str:
        return self.buckets['profile']
    
    @property
    def cover_bucket(self) -> str:
        return self.buckets['cover']
    
    @property
    def events_bucket(self) -> str:
        return self.buckets['events']
    
    @property
    def groups_bucket(self) -> str:
        return self.buckets['groups']
    
    @property
    def posts_bucket(self) -> str:
        return self.buckets['posts']
    
    @property
    def bikes_bucket(self) -> str:
        return self.buckets['bikes']