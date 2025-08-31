# users/services/supabase_service.py
import os
from supabase import create_client, Client
from django.conf import settings
import uuid
from datetime import datetime

class SupabaseStorage:
    def __init__(self):
        self.client: Client = create_client(
            settings.SUPABASE_URL,
            settings.SUPABASE_SERVICE_KEY
        )
        self.bucket = settings.SUPABASE_BUCKET
    
    def upload_profile_picture(self, file, user_id):
        # Benzersiz dosya adı oluştur
        file_extension = file.name.split('.')[-1]
        filename = f"{user_id}_{uuid.uuid4().hex}.{file_extension}"
        file_path = f"{user_id}/{filename}"
        
        # Dosyayı yükle
        result = self.client.storage.from_(self.bucket).upload(
            file_path, file.read(), file_options={"content-type": file.content_type}
        )
        
        # Public URL al
        url = self.client.storage.from_(self.bucket).get_public_url(file_path)
        
        return url
    
    def delete_profile_picture(self, url):
        # URL'den dosya yolunu çıkar
        if url and self.bucket in url:
            # URL'den dosya yolunu çıkarma
            file_path = url.split(f"/{self.bucket}/")[-1]
            try:
                self.client.storage.from_(self.bucket).remove([file_path])
                return True
            except Exception as e:
                print(f"Delete error: {e}")
                return False
        return False