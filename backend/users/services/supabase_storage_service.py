import os
import logging
from typing import Dict, Any, Optional
from supabase import Client, create_client
from django.conf import settings

logger = logging.getLogger(__name__)

class SupabaseStorageService:
    def __init__(self):
        self.client: Optional[Client] = None
        self.profile_bucket = "profile-pictures"
        self.events_bucket = "event-pictures"
        self.is_available = False
        
        try:
            # Supabase konfigürasyonu - önce environment variables, sonra settings
            supabase_url = os.getenv('SUPABASE_URL') or getattr(settings, 'SUPABASE_URL', None)
            supabase_key = os.getenv('SUPABASE_ANON_KEY') or getattr(settings, 'SUPABASE_ANON_KEY', None)
            
            # Service role key'i de dene
            if not supabase_key:
                supabase_key = os.getenv('SUPABASE_SERVICE_ROLE_KEY') or getattr(settings, 'SUPABASE_SERVICE_ROLE_KEY', None)
            
            logger.info(f"Supabase URL: {supabase_url}")
            logger.info(f"Supabase Key: {'VAR' if supabase_key else 'YOK'}")
            
            if supabase_url and supabase_key:
                self.client = create_client(supabase_url, supabase_key)
                self.is_available = True
                logger.info("✅ Supabase Storage servisi başlatıldı")
                
                # Bucket'ları kontrol et
                self._check_buckets()
            else:
                logger.warning("❌ Supabase konfigürasyonu bulunamadı")
                logger.warning(f"URL: {supabase_url}, Key: {'VAR' if supabase_key else 'YOK'}")
                
        except Exception as e:
            logger.error(f"❌ Supabase Storage servisi başlatılamadı: {e}")
            self.is_available = False

    def _check_buckets(self):
        """Bucket'ların varlığını kontrol et"""
        try:
            buckets = self.client.storage.list_buckets()
            bucket_names = [bucket.name for bucket in buckets]
            logger.info(f"📁 Mevcut bucket'lar: {bucket_names}")
            
            if self.profile_bucket not in bucket_names:
                logger.warning(f"⚠️ {self.profile_bucket} bucket bulunamadı")
            if self.events_bucket not in bucket_names:
                logger.warning(f"⚠️ {self.events_bucket} bucket bulunamadı")
                
        except Exception as e:
            logger.error(f"❌ Bucket kontrol hatası: {e}")

    def _read_file_safely(self, file) -> bytes:
        """Dosyayı güvenli şekilde oku"""
        try:
            # Dosya pozisyonunu başa al
            if hasattr(file, 'seek'):
                file.seek(0)
            
            # İlk okuma denemesi
            file_content = file.read()
            
            # Eğer boolean döndürürse alternatif yöntemler dene
            if isinstance(file_content, bool):
                logger.warning("file.read() boolean döndürdü, alternatif yöntem deneniyor")
                
                if hasattr(file, 'file') and hasattr(file.file, 'read'):
                    file.file.seek(0)
                    file_content = file.file.read()
                elif hasattr(file, 'chunks'):
                    chunks = []
                    for chunk in file.chunks():
                        chunks.append(chunk)
                    file_content = b''.join(chunks)
                else:
                    raise ValueError("Dosya okuma hatası: file.read() boolean döndürdü")
            
            # Dosya içeriğinin bytes olduğunu kontrol et
            if not isinstance(file_content, bytes):
                raise ValueError(f"Dosya içeriği bytes değil: {type(file_content)}")
            
            logger.info(f"✅ Dosya başarıyla okundu: {len(file_content)} bytes")
            return file_content
            
        except Exception as e:
            logger.error(f"❌ Dosya okuma hatası: {e}")
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
            
            # Dosyayı yükle
            result = self.client.storage.from_(self.profile_bucket).upload(
                file_name,
                file_content,
                file_options={
                    "content-type": file.content_type,
                    "upsert": True  # Aynı isimde dosya varsa üzerine yaz
                }
            )
            
            if result:
                # Public URL'i al
                public_url = self.client.storage.from_(self.profile_bucket).get_public_url(file_name)
                
                logger.info(f"✅ Profil fotoğrafı başarıyla yüklendi: {file_name}")
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
            
            # Dosyayı yükle
            result = self.client.storage.from_(self.events_bucket).upload(
                file_name,
                file_content,
                file_options={
                    "content-type": file.content_type,
                    "upsert": True
                }
            )
            
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
            
            # Dosyayı yükle
            result = self.client.storage.from_(self.profile_bucket).upload(
                file_name,
                file_content,
                file_options={
                    "content-type": file.content_type,
                    "upsert": True
                }
            )
            
            if result:
                # Public URL'i al
                public_url = self.client.storage.from_(self.profile_bucket).get_public_url(file_name)
                
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

    def delete_file(self, bucket: str, file_name: str) -> bool:
        """
        Supabase Storage'dan dosya siler
        """
        if not self.is_available:
            return False
        
        try:
            result = self.client.storage.from_(bucket).remove([file_name])
            logger.info(f"✅ Dosya silindi: {bucket}/{file_name}")
            return True
        except Exception as e:
            logger.error(f"❌ Dosya silme hatası: {e}")
            return False

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
                'events_bucket_exists': self.events_bucket in bucket_names
            }
        except Exception as e:
            logger.error(f"❌ Supabase bağlantı test hatası: {e}")
            return {
                'success': False,
                'error': f'Bağlantı test hatası: {str(e)}'
            }
