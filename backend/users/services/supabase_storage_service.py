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
        Detaylı debugging ile boolean hatası tespiti
        """
        if not self.is_available:
            return {
                'success': False,
                'error': 'Supabase Storage servisi kullanılamıyor'
            }
        
        try:
            print(f"=== EVENT PICTURE UPLOAD DEBUG ===")
            print(f"File type: {type(file)}")
            print(f"File name: {file.name}")
            print(f"File size: {file.size}")
            print(f"File content_type: {file.content_type}")
            
            # Dosya adını oluştur
            file_extension = file.name.split('.')[-1] if '.' in file.name else 'jpg'
            file_name = f"events/{event_id}/cover_{event_id}_{os.urandom(4).hex()}.{file_extension}"
            
            print(f"File name created: {file_name}")
            
            # Dosya okuma testi
            print(f"=== FILE READ TEST ===")
            try:
                print(f"Calling file.read()...")
                print(f"File object before read: {file}")
                print(f"File object type: {type(file)}")
                print(f"File object attributes: {dir(file)}")
                print(f"File closed: {file.closed if hasattr(file, 'closed') else 'N/A'}")
                print(f"File mode: {file.mode if hasattr(file, 'mode') else 'N/A'}")
                print(f"File readable: {file.readable() if hasattr(file, 'readable') else 'N/A'}")
                
                # Dosya pozisyonunu kontrol et
                if hasattr(file, 'tell'):
                    print(f"File position before read: {file.tell()}")
                
                file_content = file.read()
                print(f"file.read() result type: {type(file_content)}")
                print(f"file.read() result value: {repr(file_content[:50])}")  # İlk 50 karakter
                print(f"file.read() result length: {len(file_content) if hasattr(file_content, '__len__') else 'N/A'}")
                
                # Dosya pozisyonunu kontrol et
                if hasattr(file, 'tell'):
                    print(f"File position after read: {file.tell()}")
                
                # Boolean kontrolü
                if isinstance(file_content, bool):
                    print(f"❌ file.read() returned boolean: {file_content}")
                    print(f"❌ Boolean değer nereden geldi? Django file object problemi!")
                    
                    # Alternatif okuma yöntemleri dene
                    print(f"=== ALTERNATIVE READ METHODS ===")
                    
                    # Yöntem 1: file.file.read()
                    if hasattr(file, 'file'):
                        try:
                            print(f"Trying file.file.read()...")
                            if hasattr(file.file, 'seek'):
                                file.file.seek(0)
                            alt_content = file.file.read()
                            print(f"file.file.read() result type: {type(alt_content)}")
                            print(f"file.file.read() result length: {len(alt_content) if hasattr(alt_content, '__len__') else 'N/A'}")
                            
                            if not isinstance(alt_content, bool):
                                print(f"✅ file.file.read() başarılı!")
                                file_content = alt_content
                            else:
                                print(f"❌ file.file.read() de boolean döndürdü: {alt_content}")
                        except Exception as e:
                            print(f"❌ file.file.read() hatası: {e}")
                    
                    # Yöntem 2: chunks() kullan
                    if isinstance(file_content, bool) and hasattr(file, 'chunks'):
                        try:
                            print(f"Trying file.chunks()...")
                            chunks = []
                            for chunk in file.chunks():
                                chunks.append(chunk)
                            alt_content = b''.join(chunks)
                            print(f"file.chunks() result type: {type(alt_content)}")
                            print(f"file.chunks() result length: {len(alt_content) if hasattr(alt_content, '__len__') else 'N/A'}")
                            
                            if not isinstance(alt_content, bool):
                                print(f"✅ file.chunks() başarılı!")
                                file_content = alt_content
                            else:
                                print(f"❌ file.chunks() de boolean döndürdü: {alt_content}")
                        except Exception as e:
                            print(f"❌ file.chunks() hatası: {e}")
                    
                    # Hala boolean ise
                    if isinstance(file_content, bool):
                        return {
                            'success': False,
                            'error': f'file.read() boolean döndürdü: {file_content}. Tüm alternatif yöntemler de başarısız.'
                        }
                
                print(f"✅ file.read() başarılı, content type: {type(file_content)}")
                
            except Exception as read_error:
                print(f"❌ file.read() hatası: {read_error}")
                print(f"❌ Read error type: {type(read_error)}")
                import traceback
                traceback.print_exc()
                return {
                    'success': False,
                    'error': f'file.read() hatası: {str(read_error)}'
                }
            
            # Supabase upload testi
            print(f"=== SUPABASE UPLOAD TEST ===")
            try:
                print(f"Uploading to bucket: {self.events_bucket}")
                print(f"Uploading file: {file_name}")
                print(f"Content type: {file.content_type}")
                
                result = self.client.storage.from_(self.events_bucket).upload(
                    file_name,
                    file_content,  # file.read() sonucunu kullan
                    file_options={
                        "content-type": file.content_type,
                        "upsert": True
                    }
                )
                
                print(f"Upload result: {result}")
                print(f"Upload result type: {type(result)}")
                
            except Exception as upload_error:
                print(f"❌ Upload hatası: {upload_error}")
                print(f"❌ Upload error type: {type(upload_error)}")
                import traceback
                traceback.print_exc()
                return {
                    'success': False,
                    'error': f'Upload hatası: {str(upload_error)}'
                }
            
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
            print(f"❌ Exception: {e}")
            import traceback
            traceback.print_exc()
            return {
                'success': False,
                'error': f'Event resmi yükleme hatası: {str(e)}'
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
