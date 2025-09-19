"""
Supabase Storage Service
Temiz ve basit dosya yükleme servisi
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
    
    # Boolean kontrolü
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
            return 'image/jpeg'
    
    # None veya boş string kontrolü
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
            return 'image/jpeg'
    
    return content_type

class SupabaseStorageService:
    def __init__(self):
        self.client: Optional[Client] = None
        self.is_available = False
        
        # Bucket isimleri
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
            # Environment variables'dan al
            supabase_url = os.getenv('SUPABASE_URL') or getattr(settings, 'SUPABASE_URL', None)
            supabase_key = os.getenv('SUPABASE_SERVICE_ROLE_KEY') or getattr(settings, 'SUPABASE_SERVICE_ROLE_KEY', None)
            
            if not supabase_key:
                supabase_key = os.getenv('SUPABASE_ANON_KEY') or getattr(settings, 'SUPABASE_ANON_KEY', None)
            
            if supabase_url and supabase_key:
                self.client = create_client(supabase_url, supabase_key)
                self.is_available = True
                logger.info("✅ Supabase Storage servisi başlatıldı")
            else:
                logger.warning("❌ Supabase konfigürasyonu bulunamadı")
                self.is_available = False
                
        except Exception as e:
            logger.error(f"❌ Supabase Storage servisi başlatılamadı: {e}")
            self.is_available = False
    
    def _read_file_safely(self, file) -> bytes:
        """Dosyayı güvenli şekilde oku"""
        try:
            # Dosya pointer'ını başa al
            if hasattr(file, 'seek'):
                file.seek(0)
            
            # chunks() metodu kullan
            chunks = []
            for chunk in file.chunks():
                if isinstance(chunk, bytes):
                    chunks.append(chunk)
                else:
                    break
            
            if not chunks:
                raise ValueError("Dosya okunamadı")
            
            return b''.join(chunks)
            
        except Exception as e:
            logger.error(f"❌ Dosya okuma hatası: {e}")
            raise
    
    def upload_file(self, file, bucket_type: str, file_path: str, content_type: str = None) -> Dict[str, Any]:
        """
        Generic dosya yükleme fonksiyonu
        
        Args:
            file: Django file object
            bucket_type: 'profile', 'cover', 'events', 'groups', 'posts', 'bikes'
            file_path: Dosya yolu (örn: "username/profile_123.jpg")
            content_type: MIME type (opsiyonel)
        """
        if not self.is_available:
            return {
                'success': False,
                'error': 'Supabase Storage servisi kullanılamıyor'
            }
        
        if bucket_type not in self.buckets:
            return {
                'success': False,
                'error': f'Geçersiz bucket tipi: {bucket_type}'
            }
        
        try:
            # Dosyayı oku
            file_content = self._read_file_safely(file)
            
            # Content type'ı al
            if not content_type:
                content_type = get_safe_content_type(file)
            
            bucket_name = self.buckets[bucket_type]
            
            logger.info(f"📤 Upload: {file_path} -> {bucket_name}")
            
            # Supabase'e yükle
            result = self.client.storage.from_(bucket_name).upload(
                file_path,
                file_content,
                {
                    "content-type": content_type,
                    "upsert": True
                }
            )
            
            if result:
                # Public URL'i al
                public_url = self.client.storage.from_(bucket_name).get_public_url(file_path)
                
                logger.info(f"✅ Dosya yüklendi: {file_path}")
                return {
                    'success': True,
                    'url': public_url,
                    'file_name': file_path
                }
            else:
                logger.error("❌ Upload başarısız")
                return {
                    'success': False,
                    'error': 'Upload başarısız'
                }
                
        except Exception as e:
            logger.error(f"❌ Upload hatası: {e}")
            return {
                'success': False,
                'error': f'Upload hatası: {str(e)}'
            }
    
    # Convenience methods
    def upload_profile_picture(self, file, username: str) -> Dict[str, Any]:
        """Profil fotoğrafı yükle"""
        file_extension = file.name.split('.')[-1] if '.' in file.name else 'jpg'
        file_path = f"{username}/profile_{username}_{os.urandom(4).hex()}.{file_extension}"
        return self.upload_file(file, 'profile', file_path)
    
    def upload_cover_picture(self, file, username: str) -> Dict[str, Any]:
        """Kapak fotoğrafı yükle"""
        file_extension = file.name.split('.')[-1] if '.' in file.name else 'jpg'
        file_path = f"{username}/cover_{username}_{os.urandom(4).hex()}.{file_extension}"
        return self.upload_file(file, 'cover', file_path)
    
    def upload_event_picture(self, file, event_id: str) -> Dict[str, Any]:
        """Event fotoğrafı yükle"""
        file_extension = file.name.split('.')[-1] if '.' in file.name else 'jpg'
        file_path = f"events/{event_id}/cover_{event_id}_{os.urandom(4).hex()}.{file_extension}"
        return self.upload_file(file, 'events', file_path)
    
    def upload_group_picture(self, file, group_id: str) -> Dict[str, Any]:
        """Grup fotoğrafı yükle"""
        file_extension = file.name.split('.')[-1] if '.' in file.name else 'jpg'
        file_path = f"groups/{group_id}/profile_{group_id}_{os.urandom(4).hex()}.{file_extension}"
        return self.upload_file(file, 'groups', file_path)
    
    def upload_post_image(self, file, post_id: str) -> Dict[str, Any]:
        """Post resmi yükle"""
        file_extension = file.name.split('.')[-1] if '.' in file.name else 'jpg'
        file_path = f"posts/{post_id}/image_{post_id}_{os.urandom(4).hex()}.{file_extension}"
        return self.upload_file(file, 'posts', file_path)
    
    def upload_bike_image(self, file, bike_id: str) -> Dict[str, Any]:
        """Motosiklet resmi yükle"""
        file_extension = file.name.split('.')[-1] if '.' in file.name else 'jpg'
        file_path = f"bikes/{bike_id}/image_{bike_id}_{os.urandom(4).hex()}.{file_extension}"
        return self.upload_file(file, 'bikes', file_path)
    
    def delete_file(self, bucket_type: str, file_path: str) -> Dict[str, Any]:
        """Dosya sil"""
        if not self.is_available:
            return {
                'success': False,
                'error': 'Supabase Storage servisi kullanılamıyor'
            }
        
        if bucket_type not in self.buckets:
            return {
                'success': False,
                'error': f'Geçersiz bucket tipi: {bucket_type}'
            }
        
        try:
            bucket_name = self.buckets[bucket_type]
            result = self.client.storage.from_(bucket_name).remove([file_path])
            
            logger.info(f"✅ Dosya silindi: {file_path}")
            return {
                'success': True,
                'message': f'Dosya silindi: {file_path}'
            }
            
        except Exception as e:
            logger.error(f"❌ Dosya silme hatası: {e}")
            return {
                'success': False,
                'error': f'Dosya silme hatası: {str(e)}'
            }
    
    def test_connection(self) -> Dict[str, Any]:
        """Bağlantıyı test et"""
        if not self.is_available:
            return {
                'success': False,
                'error': 'Supabase Storage servisi kullanılamıyor'
            }
        
        try:
            buckets = self.client.storage.list_buckets()
            bucket_names = [bucket.name for bucket in buckets]
            
            return {
                'success': True,
                'buckets': bucket_names,
                'total_buckets': len(buckets)
            }
        except Exception as e:
            logger.error(f"❌ Bağlantı test hatası: {e}")
            return {
                'success': False,
                'error': f'Bağlantı test hatası: {str(e)}'
            }
