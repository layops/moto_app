from django.core.management.base import BaseCommand
from events.models import EventRequest, Event
from django.contrib.auth import get_user_model

User = get_user_model()

class Command(BaseCommand):
    help = 'EventRequest verilerini debug eder'

    def handle(self, *args, **options):
        self.stdout.write("=== EventRequest Debug ===")
        
        # Tüm EventRequest'leri listele
        all_requests = EventRequest.objects.all()
        self.stdout.write(f"Toplam EventRequest sayısı: {all_requests.count()}")
        
        if all_requests.count() == 0:
            self.stdout.write(self.style.WARNING("Hiç EventRequest bulunamadı!"))
            return
        
        self.stdout.write("\n=== EventRequest Detayları ===")
        for req in all_requests:
            self.stdout.write(
                f"ID: {req.id}, "
                f"Event: {req.event.title} (ID: {req.event.id}), "
                f"User: {req.user.username}, "
                f"Status: {req.status}, "
                f"Created: {req.created_at}"
            )
        
        # Tüm Event'leri listele
        self.stdout.write("\n=== Event Detayları ===")
        all_events = Event.objects.all()
        self.stdout.write(f"Toplam Event sayısı: {all_events.count()}")
        
        for event in all_events:
            self.stdout.write(
                f"ID: {event.id}, "
                f"Title: {event.title}, "
                f"Organizer: {event.organizer.username}, "
                f"Requests: {event.requests.count()}"
            )
        
        # Tüm User'ları listele
        self.stdout.write("\n=== User Detayları ===")
        all_users = User.objects.all()
        self.stdout.write(f"Toplam User sayısı: {all_users.count()}")
        
        for user in all_users:
            self.stdout.write(
                f"ID: {user.id}, "
                f"Username: {user.username}, "
                f"EventRequests: {user.event_requests.count()}"
            )
