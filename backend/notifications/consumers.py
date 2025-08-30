import json
from channels.generic.websocket import AsyncWebsocketConsumer
from asgiref.sync import sync_to_async
from django.contrib.auth import get_user_model
from .models import Notification
from .serializers import NotificationSerializer

User = get_user_model()

class NotificationConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        if not self.scope["user"].is_authenticated:
            await self.close()
            return

        self.user = self.scope["user"]
        self.user_group_name = f'user_notifications_{self.user.id}'

        await self.channel_layer.group_add(self.user_group_name, self.channel_name)
        await self.accept()
        print(f"DEBUG: Notification WebSocket bağlandı: {self.user.username}")

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(self.user_group_name, self.channel_name)
        print(f"DEBUG: WebSocket bağlantısı kesildi: {self.user.username}, Kod: {close_code}")

    async def send_notification(self, event):
        notification_data = event.get('notification')
        if notification_data:
            await self.send(text_data=json.dumps(notification_data))

    async def receive(self, text_data):
        pass

    @sync_to_async
    def mark_notification_as_read(self, notification_id):
        try:
            notification = Notification.objects.get(id=notification_id, recipient=self.user)
            notification.is_read = True
            notification.save()
            return True
        except Notification.DoesNotExist:
            return False
