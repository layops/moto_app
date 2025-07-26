from django.core.management.base import BaseCommand, CommandError
from django.contrib.auth import get_user_model
from notifications.utils import send_realtime_notification # Yardımcı fonksiyonumuzu import ediyoruz

User = get_user_model()

class Command(BaseCommand):
    help = 'Belirli bir kullanıcıya test bildirimi gönderir ve WebSocket üzerinden iletir.'

    def add_arguments(self, parser):
        parser.add_argument('username', type=str, help='Bildirimin gönderileceği kullanıcının kullanıcı adı')
        parser.add_argument('message', type=str, help='Bildirim mesajı')
        parser.add_argument(
            '--type', 
            type=str, 
            default='other', 
            help='Bildirim türü (örn: message, group_invite, ride_request, other)'
        )
        parser.add_argument(
            '--sender_username', 
            type=str, 
            default=None, 
            help='Bildirimi gönderen kullanıcının kullanıcı adı (isteğe bağlı)'
        )

    def handle(self, *args, **options):
        username = options['username']
        message = options['message']
        notification_type = options['type']
        sender_username = options['sender_username']

        try:
            recipient_user = User.objects.get(username=username)
        except User.DoesNotExist:
            raise CommandError(f'Kullanıcı "{username}" bulunamadı.')

        sender_user = None
        if sender_username:
            try:
                sender_user = User.objects.get(username=sender_username)
            except User.DoesNotExist:
                raise CommandError(f'Gönderen kullanıcı "{sender_username}" bulunamadı.')

        # Yardımcı fonksiyonu çağırarak bildirimi oluştur ve gönder
        send_realtime_notification(
            recipient_user=recipient_user,
            message=message,
            notification_type=notification_type,
            sender_user=sender_user
        )

        self.stdout.write(self.style.SUCCESS(f'Bildirim "{message}" "{username}" kullanıcısına başarıyla gönderildi.'))

