import os
from supabase import create_client, Client
from django.conf import settings
import uuid
from datetime import datetime
from django.core.files.uploadedfile import InMemoryUploadedFile

class SupabaseStorage:
    def __init__(self):
        # Ortam değişkenlerinin varlığını kontrol et
        supabase_url = settings.SUPABASE_URL
        supabase_key = settings.SUPABASE_SERVICE_KEY
        
        if not supabase_url or not supabase_key:
            raise ValueError("Supabase URL veya Service Key tanımlanmamış. Lütfen ortam değişkenlerini kontrol edin.")

        self.client: Client = create_client(supabase_url, supabase_key)
        self.bucket = settings.SUPABASE_BUCKET
    
    def upload_profile_picture(self, file: InMemoryUploadedFile, user_id):
        # Benzersiz dosya adı oluştur
        file_extension = file.name.split('.')[-1]
        filename = f"{user_id}_{uuid.uuid4().hex}.{file_extension}"
        file_path = f"profile_pictures/{filename}"  # Klasör adı ekledim
        
        # Dosyayı yükle
        with file.open('rb') as f:
            result = self.client.storage.from_(self.bucket).upload(
                file_path, f.read(), file_options={"content-type": file.content_type}
            )
        
        # Public URL al
        url = self.client.storage.from_(self.bucket).get_public_url(file_path)
        
        return url
    
    def delete_profile_picture(self, url):
        # URL'den dosya yolunu çıkar
        if url and self.bucket in url:
            file_path = url.split(f"/{self.bucket}/")[-1]
            try:
                self.client.storage.from_(self.bucket).remove([file_path])
                return True
            except Exception as e:
                print(f"Supabase'den dosya silinirken hata: {e}")
                return False
        return False