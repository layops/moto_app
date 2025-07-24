import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async  # Veritabanı işlemleri için
from django.contrib.auth import get_user_model
from .models import PrivateMessage

User = get_user_model()

class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.group_id = self.scope['url_route']['kwargs']['group_id']
        self.group_name = f'chat_{self.group_id}'

        if self.scope["user"].is_authenticated:
            print(f"DEBUG CONSUMER: Kullanıcı '{self.scope['user'].username}' (ID: {self.scope['user'].id}) sohbet grubuna bağlanıyor: {self.group_name}")
            await self.channel_layer.group_add(
                self.group_name,
                self.channel_name
            )
            await self.accept()
            await self.send(text_data=json.dumps({
                'type': 'connection_established',
                'message': f"Sohbet odası {self.group_id} ile bağlantı kuruldu. Kullanıcı: {self.scope['user'].username}"
            }))
        else:
            print(f"DEBUG CONSUMER: Kimliği doğrulanmamış kullanıcı bağlantı denemesi. Grup ID: {self.group_id}")
            await self.close(code=4003)

    async def disconnect(self, close_code):
        print(f"DEBUG CONSUMER: Bağlantı kesildi. Kullanıcı: {self.scope['user'].username if self.scope['user'].is_authenticated else 'AnonymousUser'}. Kod: {close_code}")
        if self.scope["user"].is_authenticated:
            await self.channel_layer.group_discard(
                self.group_name,
                self.channel_name
            )

    async def receive(self, text_data):
        text_data_json = json.loads(text_data)
        message = text_data_json['message']

        if self.scope["user"].is_authenticated:
            username = self.scope['user'].username
            user_id = self.scope['user'].id
            print(f"DEBUG CONSUMER: Kullanıcı '{username}' (ID: {user_id}) mesaj gönderdi: {message}")

            await self.channel_layer.group_send(
                self.group_name,
                {
                    'type': 'chat_message',
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

    async def chat_message(self, event):
        await self.send(text_data=json.dumps({
            'type': 'chat_message',
            'message': event['message'],
            'username': event['username'],
            'user_id': event['user_id'],
        }))


class PrivateChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.user1_id = int(self.scope['url_route']['kwargs']['user1_id'])
        self.user2_id = int(self.scope['url_route']['kwargs']['user2_id'])
        current_user_id = self.scope['user'].id

        if not self.scope["user"].is_authenticated or \
           (current_user_id != self.user1_id and current_user_id != self.user2_id):
            print(f"DEBUG PRIVATE CONSUMER: Kimliği doğrulanmamış veya yetkisiz kullanıcı özel sohbet denemesi. User1: {self.user1_id}, User2: {self.user2_id}")
            await self.close(code=4003)
            return

        user_ids = sorted([self.user1_id, self.user2_id])
        self.room_name = f'private_chat_{user_ids[0]}_{user_ids[1]}'
        self.room_group_name = f'chat_{self.room_name}'

        print(f"DEBUG PRIVATE CONSUMER: Kullanıcı '{self.scope['user'].username}' (ID: {current_user_id}) özel sohbet odasına bağlanıyor: {self.room_group_name}")

        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )
        await self.accept()
        await self.send(text_data=json.dumps({
            'type': 'connection_established',
            'message': f"Özel sohbet odası {self.room_name} ile bağlantı kuruldu. Kullanıcı: {self.scope['user'].username}"
        }))

    async def disconnect(self, close_code):
        print(f"DEBUG PRIVATE CONSUMER: Özel sohbet bağlantısı kesildi. Kullanıcı: {self.scope['user'].username if self.scope['user'].is_authenticated else 'AnonymousUser'}. Kod: {close_code}")
        if self.scope["user"].is_authenticated:
            await self.channel_layer.group_discard(
                self.room_group_name,
                self.channel_name
            )

    async def receive(self, text_data):
        text_data_json = json.loads(text_data)
        message_content = text_data_json['message']
        receiver_id = text_data_json.get('receiver_id')

        if not self.scope["user"].is_authenticated:
            await self.send(text_data=json.dumps({
                'type': 'error',
                'message': 'Kimlik doğrulanmamış kullanıcı mesaj gönderemez.'
            }))
            return

        sender_user = self.scope['user']

        try:
            receiver_user = await database_sync_to_async(User.objects.get)(id=receiver_id)
        except User.DoesNotExist:
            await self.send(text_data=json.dumps({
                'type': 'error',
                'message': 'Alıcı kullanıcı bulunamadı.'
            }))
            return

        print(f"DEBUG PRIVATE CONSUMER: Kullanıcı '{sender_user.username}' (ID: {sender_user.id}) '{receiver_user.username}' (ID: {receiver_user.id})'a özel mesaj gönderdi: {message_content}")

        await database_sync_to_async(PrivateMessage.objects.create)(
            sender=sender_user,
            receiver=receiver_user,
            message=message_content
        )

        latest_message = await database_sync_to_async(PrivateMessage.objects.latest)('timestamp')

        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'private_chat_message',
                'message': message_content,
                'sender_username': sender_user.username,
                'sender_id': sender_user.id,
                'receiver_username': receiver_user.username,
                'receiver_id': receiver_user.id,
                'timestamp': str(latest_message.timestamp),
            }
        )

    async def private_chat_message(self, event):
        await self.send(text_data=json.dumps({
            'type': 'private_chat_message',
            'message': event['message'],
            'sender_username': event['sender_username'],
            'sender_id': event['sender_id'],
            'receiver_username': event['receiver_username'],
            'receiver_id': event['receiver_id'],
            'timestamp': event['timestamp'],
        }))
