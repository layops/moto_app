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
                    else:
                        scope['user'] = AnonymousUser()
                except Token.DoesNotExist:
                    scope['user'] = AnonymousUser()
                except Exception as e:
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

                try:
                    # Token nesnesini eşzamansız al
                    token_obj = await sync_to_async(Token.objects.get)(key=token_key)
                    user = await sync_to_async(lambda: token_obj.user)()

                    if user.is_active:
                        scope['user'] = user
                    else:
                        scope['user'] = AnonymousUser()
                except Token.DoesNotExist:
                    scope['user'] = AnonymousUser()
                except Exception as e:
                    scope['user'] = AnonymousUser()
            else:
                scope['user'] = AnonymousUser()

        return await self.app(scope, receive, send)


# Ana ASGI uygulaması

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