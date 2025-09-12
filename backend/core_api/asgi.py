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
        # HTTP istekleri için token doğrulama ekleyelim
        if scope['type'] == 'http':
            headers = dict(scope['headers'])
            auth_header = headers.get(b'authorization', b'').decode('utf-8')
            
            if auth_header.startswith('Token '):
                token_key = auth_header[6:].strip()
                print(f"DEBUG ASGI (HTTP): Token bulundu, başlangıç: {token_key[:5]}...")
                
                # Gerekli importları burada yapıyoruz
                from rest_framework.authtoken.models import Token
                from django.contrib.auth.models import AnonymousUser
                from asgiref.sync import sync_to_async
                
                try:
                    # Token nesnesini eşzamansız al
                    token_obj = await sync_to_async(Token.objects.get)(key=token_key)
                    user = await sync_to_async(lambda: token_obj.user)()
                    
                    if user.is_active:
                        scope['user'] = user
                        print(f"DEBUG ASGI (HTTP): Kullanıcı doğrulandı: {user.username}")
                    else:
                        print(f"DEBUG ASGI (HTTP): Kullanıcı aktif değil: {user.username}")
                        scope['user'] = AnonymousUser()
                except Token.DoesNotExist:
                    print(f"DEBUG ASGI (HTTP): Token bulunamadı: {token_key[:5]}...")
                    scope['user'] = AnonymousUser()
                except Exception as e:
                    print(f"DEBUG ASGI (HTTP): Token doğrulama hatası: {e}")
                    scope['user'] = AnonymousUser()
        
        # WebSocket için orijinal doğrulama
        if scope['type'] == 'websocket':
            query_string = scope.get('query_string', b'').decode('utf-8')
            query_params = parse_qs(query_string)
            token_key_list = query_params.get('token')

            # Gerekli importları burada yapıyoruz
            from rest_framework.authtoken.models import Token
            from django.contrib.auth.models import AnonymousUser
            from asgiref.sync import sync_to_async

            scope['user'] = AnonymousUser()  # Default anonymous user

            if token_key_list:
                token_key = token_key_list[0]
                print(f"DEBUG ASGI (WS): Token bulundu, başlangıç: {token_key[:5]}...")

                try:
                    # Token nesnesini eşzamansız al
                    token_obj = await sync_to_async(Token.objects.get)(key=token_key)
                    user = await sync_to_async(lambda: token_obj.user)()

                    if user.is_active:
                        scope['user'] = user
                        print(f"DEBUG ASGI (WS): Kullanıcı doğrulandı: {user.username}")
                    else:
                        print(f"DEBUG ASGI (WS): Token geçerli ama kullanıcı aktif değil: {user.username}")
                except Token.DoesNotExist:
                    print(f"DEBUG ASGI (WS): Token veritabanında bulunamadı: {token_key[:5]}...")
                except Exception as e:
                    print(f"DEBUG ASGI (WS): Token doğrulama hatası: {e}")
            else:
                print("DEBUG ASGI (WS): Sorgu parametrelerinde 'token' bulunamadı.")

        return await self.app(scope, receive, send)


# Ana ASGI uygulaması
print("DEBUG: asgi.py yüklendi - HTTP ve WS Token Doğrulamalı")

# WebSocket URL desenlerini import et
import chat.routing

application = ProtocolTypeRouter({
    "http": AuthTokenMiddleware(django_asgi_app),  # HTTP için de token middleware ekledik
    "websocket": AuthTokenMiddleware(
        URLRouter(
            chat.routing.websocket_urlpatterns
        )
    ),
})