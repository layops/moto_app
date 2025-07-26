# moto_app/backend/core_api/asgi.py

import os
from django.core.asgi import get_asgi_application
from channels.routing import ProtocolTypeRouter, URLRouter
from urllib.parse import parse_qs

# Django ortamını ayarla ve ASGI uygulamasını al
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core_api.settings')
django_asgi_app = get_asgi_application()

# Özel WebSocket kimlik doğrulama middleware'i (token bazlı)
class AuthTokenMiddleware:
    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope['type'] == 'websocket':
            query_string = scope.get('query_string', b'').decode('utf-8')
            query_params = parse_qs(query_string)
            token_key_list = query_params.get('token')

            # Gerekli importları burada yapıyoruz (asgiref, Django modeller vs)
            from rest_framework.authtoken.models import Token
            from django.contrib.auth.models import AnonymousUser
            from asgiref.sync import sync_to_async

            scope['user'] = AnonymousUser()  # Default anonymous user

            if token_key_list:
                token_key = token_key_list[0]
                print(f"DEBUG ASGI: Token bulundu, başlangıç: {token_key[:5]}...")

                try:
                    # Token nesnesini eşzamansız al
                    token_obj = await sync_to_async(Token.objects.get)(key=token_key)
                    user = await sync_to_async(lambda: token_obj.user)()

                    if user.is_active:
                        scope['user'] = user
                        print(f"DEBUG ASGI: Kullanıcı doğrulandı: {user.username} (ID: {user.id})")
                    else:
                        print(f"DEBUG ASGI: Token geçerli ama kullanıcı aktif değil: {user.username}")
                except Token.DoesNotExist:
                    print(f"DEBUG ASGI: Token veritabanında bulunamadı: {token_key[:5]}...")
                except Exception as e:
                    print(f"DEBUG ASGI: Token doğrulama hatası: {e}")
            else:
                print("DEBUG ASGI: Sorgu parametrelerinde 'token' bulunamadı.")

        return await self.app(scope, receive, send)


# Ana ASGI uygulaması

print("DEBUG: asgi.py yüklendi - Versiyon 20250724_1")

# WebSocket URL desenlerini import et
import chat.routing

print(f"DEBUG ASGI: URLRouter'a verilecek websocket desenleri: {chat.routing.websocket_urlpatterns}")

application = ProtocolTypeRouter({
    "http": django_asgi_app,
    "websocket": AuthTokenMiddleware(
        URLRouter(
            chat.routing.websocket_urlpatterns
        )
    ),
})
