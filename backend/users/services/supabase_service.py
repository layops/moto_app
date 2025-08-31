# users/services/supabase_service.py
from django.conf import settings
from supabase import create_client

class SupabaseStorage:
    def __init__(self):
        supabase_url = settings.SUPABASE_URL
        supabase_key = settings.SUPABASE_SERVICE_KEY
        self.bucket = settings.SUPABASE_BUCKET
        # Proxy parametresi kaldırıldı, SDK ile uyumlu
        self.client = create_client(supabase_url, supabase_key)

    def upload_profile_picture(self, file, user_id):
        """
        Profil fotoğrafı yükler ve public URL döner.
        """
        file_path = f"{user_id}/{file.name}"

        # Dosyayı byte olarak oku ve yükle
        with file.open('rb') as f:
            self.client.storage.from_(self.bucket).upload(
                file_path, f.read(), content_type=file.content_type
            )

        # Public URL al
        url = self.client.storage.from_(self.bucket).get_public_url(file_path).public_url
        return url
