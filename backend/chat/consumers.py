import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async # Veritabanı işlemleri için

# Django User modelini import ediyoruz
from django.contrib.auth import get_user_model
User = get_user_model()

class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        # URL'den group_id'yi alıyoruz (routing.py'den gelir)
        self.group_id = self.scope['url_route']['kwargs']['group_id']
        self.group_name = f'chat_{self.group_id}'

        # Kullanıcının kimliği doğrulanmış mı kontrol et
        if self.scope["user"].is_authenticated:
            print(f"DEBUG CONSUMER: Kullanıcı '{self.scope['user'].username}' (ID: {self.scope['user'].id}) sohbet grubuna bağlanıyor: {self.group_name}")
            
            # Gruba katıl
            await self.channel_layer.group_add(
                self.group_name,
                self.channel_name
            )
            await self.accept() # Bağlantıyı kabul et
            await self.send(text_data=json.dumps({
                'type': 'connection_established',
                'message': f"Sohbet odası {self.group_id} ile bağlantı kuruldu. Kullanıcı: {self.scope['user'].username}"
            }))
        else:
            print(f"DEBUG CONSUMER: Kimliği doğrulanmamış kullanıcı bağlantı denemesi. Grup ID: {self.group_id}")
            await self.close(code=4003) # 4003: Kimlik doğrulama başarısız (özel kod)

    async def disconnect(self, close_code):
        print(f"DEBUG CONSUMER: Bağlantı kesildi. Kullanıcı: {self.scope['user'].username if self.scope['user'].is_authenticated else 'AnonymousUser'}. Kod: {close_code}")
        # Gruptan ayrıl
        if self.scope["user"].is_authenticated:
            await self.channel_layer.group_discard(
                self.group_name,
                self.channel_name
            )

    async def receive(self, text_data):
        text_data_json = json.loads(text_data)
        message = text_data_json['message']
        
        # Sadece kimliği doğrulanmış kullanıcıların mesaj göndermesine izin ver
        if self.scope["user"].is_authenticated:
            username = self.scope['user'].username
            user_id = self.scope['user'].id
            print(f"DEBUG CONSUMER: Kullanıcı '{username}' (ID: {user_id}) mesaj gönderdi: {message}")

            # Mesajı grup katmanına gönder
            await self.channel_layer.group_send(
                self.group_name,
                {
                    'type': 'chat_message', # Alıcı consumer'ın çağıracağı metod adı
                    'message': message,
                    'username': username,
                    'user_id': user_id,
                }
            )
        else:
            await self.send(text_data=json.dumps({
                'type': 'error',
                'message': 'Kimlik doğrulanmamış kullanıcı mesaj gönderemez.'
            }))

    # Gruptan mesaj alındığında çağrılan metod
    async def chat_message(self, event):
        message = event['message']
        username = event['username']
        user_id = event['user_id']

        # WebSocket üzerinden istemciye mesaj gönder
        await self.send(text_data=json.dumps({
            'type': 'chat_message',
            'message': message,
            'username': username,
            'user_id': user_id,
        }))