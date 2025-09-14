from django.core.management.base import BaseCommand
from events.models import EventRequest, Event
from django.contrib.auth import get_user_model

User = get_user_model()

class Command(BaseCommand):
    help = 'Test EventRequest oluşturur'

    def add_arguments(self, parser):
        parser.add_argument('--event-id', type=int, help='Event ID')
        parser.add_argument('--user-id', type=int, help='User ID')
        parser.add_argument('--message', type=str, default='Test mesajı', help='İstek mesajı')

    def handle(self, *args, **options):
        event_id = options.get('event_id')
        user_id = options.get('user_id')
        message = options.get('message')
        
        if not event_id or not user_id:
            self.stdout.write("Event ID ve User ID gerekli!")
            self.stdout.write("Kullanım: python manage.py create_test_eventrequest --event-id 1 --user-id 1")
            return
        
        try:
            event = Event.objects.get(id=event_id)
            user = User.objects.get(id=user_id)
            
            self.stdout.write(f"Event: {event.title} (ID: {event.id})")
            self.stdout.write(f"User: {user.username} (ID: {user.id})")
            
            # EventRequest oluştur
            event_request, created = EventRequest.objects.get_or_create(
                event=event,
                user=user,
                defaults={'message': message}
            )
            
            if created:
                self.stdout.write(
                    self.style.SUCCESS(f'EventRequest oluşturuldu - ID: {event_request.id}')
                )
            else:
                self.stdout.write(
                    self.style.WARNING(f'EventRequest zaten mevcut - ID: {event_request.id}')
                )
            
            self.stdout.write(f"Status: {event_request.status}")
            self.stdout.write(f"Message: {event_request.message}")
            self.stdout.write(f"Created: {event_request.created_at}")
            
        except Event.DoesNotExist:
            self.stdout.write(self.style.ERROR(f"Event ID {event_id} bulunamadı"))
        except User.DoesNotExist:
            self.stdout.write(self.style.ERROR(f"User ID {user_id} bulunamadı"))
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"Hata: {str(e)}"))
