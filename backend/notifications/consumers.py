# moto_app/backend/notifications/consumers.py

import json
from channels.generic.websocket import AsyncWebsocketConsumer
from asgiref.sync import sync_to_async
from django.contrib.auth import get_user_model

# Bildirim modelimizi ve serileştiricimizi import ediyoruz
from .models import Notification
from .serializers import NotificationSerializer

User = get_user_model()

class NotificationConsumer(AsyncWebsocketConsumer):
    """
    Kullanıcılara gerçek zamanlı bildirimler gönderen WebSocket Consumer.
    Her kullanıcı kendi kanal grubuna abone olur.
    """
    async def connect(self):
        if not self.scope["user"].is_authenticated:
            await self.close()
            return

        self.user = self.scope["user"]
        self.user_group_name = f'user_notifications_{self.user.id}'

        await self.channel_layer.group_add(
            self.user_group_name,
            self.channel_name
        )
        await self.accept()
        print(f"DEBUG: Notification WebSocket bağlandı: Kullanıcı {self.user.username}, Grup: {self.user_group_name}")

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(
            self.user_group_name,
            self.channel_name
        )
        print(f"DEBUG: Notification WebSocket bağlantısı kesildi: Kullanıcı {self.user.username}, Kapanma Kodu: {close_code}")

    # Gruptan gelen mesajları al (bildirim göndermek için)
    async def send_notification(self, event):
        """
        Kanal katmanından gelen 'send_notification' olayını işler
        ve bildirimi WebSocket üzerinden istemciye gönderir.
        """
        print(f"DEBUG CONSUMER: send_notification metodu çağrıldı. Gelen event: {event}")
        
        # Olayın 'notification' anahtarı altında bildirim verisi olmalı
        notification_data = event.get('notification') 

        if not notification_data:
            print("ERROR CONSUMER: 'notification' anahtarı event içinde bulunamadı.")
            return

        try:
            # Bildirim verisini JSON formatında istemciye gönder
            await self.send(text_data=json.dumps(notification_data))
            print(f"DEBUG CONSUMER: Bildirim gönderildi (WebSocket): Kullanıcı {self.user.username}, Mesaj: {notification_data.get('message', 'Mesaj Yok')}")
        except Exception as e:
            print(f"ERROR CONSUMER: WebSocket'e bildirim gönderilirken hata oluştu: {e}")
            # Hata durumunda bağlantıyı kapatmak isteyebilirsiniz
            # await self.close() 

    async def receive(self, text_data):
        # Bildirimler genellikle sunucudan istemciye tek yönlüdür.
        pass

    @sync_to_async
    def mark_notification_as_read(self, notification_id):
        try:
            notification = Notification.objects.get(id=notification_id, recipient=self.user)
            notification.is_read = True
            notification.save()
            print(f"DEBUG: Bildirim okundu olarak işaretlendi: ID {notification_id}")
            return True
        except Notification.DoesNotExist:
            print(f"DEBUG: Bildirim bulunamadı veya kullanıcıya ait değil: ID {notification_id}")
            return False

