import os
from supabase import create_client, Client
from django.conf import settings
import uuid
from datetime import datetime
from django.core.files.uploadedfile import InMemoryUploadedFile
import logging

logger = logging.getLogger(__name__)

class SupabaseStorage:
    def __init__(self):
        try:
            supabase_url = settings.SUPABASE_URL
            supabase_key = settings.SUPABASE_SERVICE_KEY
            
            if not supabase_url or not supabase_key:
                raise ValueError("Supabase URL veya Service Key tanımlanmamış")
            
            self.client: Client = create_client(supabase_url, supabase_key)
            self.bucket = settings.SUPABASE_BUCKET
            
            # Bağlantı testi
            self.client.storage.list_buckets()
            
        except Exception as e:
            logger.error(f"Supabase connection error: {str(e)}")
            raise
    
    def upload_profile_picture(self, file: InMemoryUploadedFile, user_id):
        try:
            file_extension = file.name.split('.')[-1]
            filename = f"{user_id}_{uuid.uuid4().hex}.{file_extension}"
            file_path = f"profile_pictures/{filename}"
            
            with file.open('rb') as f:
                result = self.client.storage.from_(self.bucket).upload(
                    file_path, f.read(), file_options={"content-type": file.content_type}
                )
            
            url = self.client.storage.from_(self.bucket).get_public_url(file_path)
            return url
            
        except Exception as e:
            logger.error(f"Upload error: {str(e)}")
            raise
    
    def delete_profile_picture(self, url):
        try:
            if url and self.bucket in url:
                file_path = url.split(f"/{self.bucket}/")[-1]
                self.client.storage.from_(self.bucket).remove([file_path])
                return True
            return False
        except Exception as e:
            logger.error(f"Delete error: {str(e)}")
            return False