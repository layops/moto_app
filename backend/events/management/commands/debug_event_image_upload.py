from django.core.management.base import BaseCommand
from events.models import Event
from django.contrib.auth import get_user_model
from users.services.supabase_storage_service import SupabaseStorageService
from django.utils import timezone
import os
import tempfile
from PIL import Image

User = get_user_model()

class Command(BaseCommand):
    help = 'Event image upload sürecini debug eder'

    def add_arguments(self, parser):
        parser.add_argument('--event-id', type=int, help='Event ID')
        parser.add_argument('--create-test-image', action='store_true', help='Test resmi oluştur')

    def handle(self, *args, **options):
        self.stdout.write("=== Event Image Upload Debug ===")
        
        # Supabase Storage servisini test et
        self.stdout.write("\n1. Supabase Storage Servisi Test")
        storage_service = SupabaseStorageService()
        self.stdout.write(f"Supabase Storage Available: {storage_service.is_available}")
        
        if not storage_service.is_available:
            self.stdout.write(self.style.ERROR("❌ Supabase Storage servisi kullanılamıyor!"))
            return
        
        # Test resmi oluştur
        if options.get('create_test_image'):
            self.stdout.write("\n2. Test Resmi Oluşturuluyor")
            test_image_path = self._create_test_image()
            if test_image_path:
                self.stdout.write(f"✅ Test resmi oluşturuldu: {test_image_path}")
                
                # Test event oluştur
                event = self._create_test_event()
                if event:
                    self.stdout.write(f"✅ Test event oluşturuldu: {event.id}")
                    
                    # Resmi yükle
                    self.stdout.write("\n3. Test Resmi Yükleniyor")
                    with open(test_image_path, 'rb') as f:
                        # Mock file object oluştur
                        class MockFile:
                            def __init__(self, file_path):
                                self.name = os.path.basename(file_path)
                                self.size = os.path.getsize(file_path)
                                self.content_type = 'image/png'
                                self._file_path = file_path
                            
                            def seek(self, pos):
                                pass
                            
                            def read(self):
                                with open(self._file_path, 'rb') as f:
                                    return f.read()
                        
                        mock_file = MockFile(test_image_path)
                        result = storage_service.upload_event_picture(mock_file, str(event.id))
                        
                        self.stdout.write(f"Upload Result: {result}")
                        
                        if result.get('success'):
                            self.stdout.write(self.style.SUCCESS("✅ Resim başarıyla yüklendi!"))
                            event.event_image = result.get('url')
                            event.save()
                            self.stdout.write(f"Event URL güncellendi: {event.event_image}")
                        else:
                            self.stdout.write(self.style.ERROR(f"❌ Resim yükleme başarısız: {result.get('error')}"))
                    
                    # Test resmini sil
                    os.unlink(test_image_path)
                else:
                    self.stdout.write(self.style.ERROR("❌ Test event oluşturulamadı"))
            else:
                self.stdout.write(self.style.ERROR("❌ Test resmi oluşturulamadı"))
        
        # Mevcut event'leri kontrol et
        self.stdout.write("\n4. Mevcut Event'ler ve Resimleri")
        events = Event.objects.all()[:5]  # İlk 5 event
        for event in events:
            self.stdout.write(f"Event ID: {event.id}, Title: {event.title}")
            self.stdout.write(f"  Event Image URL: {event.event_image}")
            self.stdout.write(f"  Has Image: {bool(event.event_image)}")
            self.stdout.write("---")

    def _create_test_image(self):
        """Test için basit bir resim oluştur"""
        try:
            # 100x100 piksel basit bir resim oluştur
            img = Image.new('RGB', (100, 100), color='red')
            
            # Geçici dosya oluştur
            with tempfile.NamedTemporaryFile(suffix='.png', delete=False) as tmp:
                img.save(tmp.name)
                return tmp.name
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"Test resmi oluşturma hatası: {e}"))
            return None

    def _create_test_event(self):
        """Test için basit bir event oluştur"""
        try:
            user = User.objects.first()
            if not user:
                self.stdout.write(self.style.ERROR("❌ Hiç kullanıcı bulunamadı"))
                return None
            
            event = Event.objects.create(
                title="Test Event - Image Upload",
                description="Bu bir test event'idir",
                location="Test Location",
                start_time=timezone.now() + timezone.timedelta(hours=1),
                organizer=user,
                is_public=True
            )
            return event
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"Test event oluşturma hatası: {e}"))
            return None
