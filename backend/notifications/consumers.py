import json
import logging
from channels.generic.websocket import AsyncWebsocketConsumer
from asgiref.sync import sync_to_async
from django.contrib.auth import get_user_model
from .models import Notification
from .serializers import NotificationSerializer

User = get_user_model()
logger = logging.getLogger(__name__)

class NotificationConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        # Token tabanlı authentication kontrolü
        token = self.scope.get('query_string', b'').decode('utf-8')
        if 'token=' not in token:
            logger.warning("WebSocket bağlantısı reddedildi: Token bulunamadı")
            await self.close(code=4001)
            return

        if not self.scope["user"].is_authenticated:
            logger.warning("WebSocket bağlantısı reddedildi: Kullanıcı kimlik doğrulaması başarısız")
            await self.close(code=4001)
            return

        self.user = self.scope["user"]
        self.user_group_name = f'user_notifications_{self.user.id}'

        try:
            await self.channel_layer.group_add(self.user_group_name, self.channel_name)
            await self.accept()
            logger.info(f"WebSocket bağlantısı başarılı: {self.user.username} (ID: {self.user.id})")
        except Exception as e:
            logger.error(f"WebSocket bağlantı hatası: {e}")
            await self.close(code=4000)

    async def disconnect(self, close_code):
        try:
            await self.channel_layer.group_discard(self.user_group_name, self.channel_name)
            logger.info(f"WebSocket bağlantısı kesildi: {self.user.username}, Kod: {close_code}")
        except Exception as e:
            logger.error(f"WebSocket bağlantı kesme hatası: {e}")

    async def send_notification(self, event):
        try:
            notification_data = event.get('notification')
            if notification_data:
                await self.send(text_data=json.dumps(notification_data))
                logger.debug(f"Bildirim gönderildi: {self.user.username}")
            else:
                logger.warning("Boş bildirim verisi alındı")
        except Exception as e:
            logger.error(f"Bildirim gönderme hatası: {e}")

    async def receive(self, text_data):
        try:
            data = json.loads(text_data)
            action = data.get('action')
            
            if action == 'mark_read':
                notification_id = data.get('notification_id')
                if notification_id:
                    success = await self.mark_notification_as_read(notification_id)
                    await self.send(text_data=json.dumps({
                        'action': 'mark_read_response',
                        'success': success,
                        'notification_id': notification_id
                    }))
        except json.JSONDecodeError:
            logger.error("Geçersiz JSON verisi alındı")
        except Exception as e:
            logger.error(f"WebSocket mesaj işleme hatası: {e}")

    @sync_to_async
    def mark_notification_as_read(self, notification_id):
        try:
            notification = Notification.objects.get(
                id=notification_id, 
                recipient=self.user
            )
            notification.is_read = True
            notification.save()
            logger.info(f"Bildirim okundu olarak işaretlendi: {notification_id}")
            return True
        except Notification.DoesNotExist:
            logger.warning(f"Bildirim bulunamadı: {notification_id}")
            return False
        except Exception as e:
            logger.error(f"Bildirim işaretleme hatası: {e}")
            return False
