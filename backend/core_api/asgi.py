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
        # Render.com için WebSocket upgrade header'larını kontrol et
        if scope['type'] == 'websocket':
            headers = dict(scope.get('headers', []))
            upgrade_header = headers.get(b'upgrade', b'').decode('utf-8').lower()
            connection_header = headers.get(b'connection', b'').decode('utf-8').lower()
            path = scope.get('path', '')
            
            print(f"DEBUG ASGI (WS): WebSocket isteği geldi - Path: {path}")
            print(f"DEBUG ASGI (WS): Upgrade: {upgrade_header}, Connection: {connection_header}")
            
            if upgrade_header == 'websocket' and 'upgrade' in connection_header:
                print("DEBUG ASGI (WS): WebSocket upgrade detected")
            else:
                print(f"DEBUG ASGI (WS): WebSocket upgrade başarısız")
        # HTTP istekleri için minimal debug log
        if scope['type'] == 'http':
            path = scope.get('path', '')
            if '/api/chat/rooms/' in path:
                print(f"DEBUG ASGI (HTTP): Chat room request: {path}")
        
        # WebSocket için JWT ve Token doğrulama
        if scope['type'] == 'websocket':
            query_string = scope.get('query_string', b'').decode('utf-8')
            query_params = parse_qs(query_string)
            token_key_list = query_params.get('token')

            # Gerekli importları burada yapıyoruz
            from rest_framework.authtoken.models import Token
            from django.contrib.auth.models import AnonymousUser
            from asgiref.sync import sync_to_async
            from rest_framework_simplejwt.tokens import AccessToken
            from django.contrib.auth import get_user_model

            User = get_user_model()
            scope['user'] = AnonymousUser()  # Default anonymous user

            if token_key_list:
                token_key = token_key_list[0]
                print(f"DEBUG ASGI (WS): Token bulundu, başlangıç: {token_key[:5]}...")

                # Önce JWT token olarak dene
                try:
                    # JWT token doğrulama
                    access_token = AccessToken(token_key)
                    user_id = access_token['user_id']
                    user = await sync_to_async(User.objects.get)(id=user_id)
                    
                    if user.is_active:
                        scope['user'] = user
                        print(f"DEBUG ASGI (WS): JWT Token ile kullanıcı doğrulandı: {user.username}")
                    else:
                        print(f"DEBUG ASGI (WS): JWT Token geçerli ama kullanıcı aktif değil: {user.username}")
                        
                except Exception as jwt_error:
                    print(f"DEBUG ASGI (WS): JWT Token doğrulama başarısız: {jwt_error}")
                    
                    # JWT başarısız olursa DRF Token olarak dene
                    try:
                        token_obj = await sync_to_async(Token.objects.get)(key=token_key)
                        user = await sync_to_async(lambda: token_obj.user)()

                        if user.is_active:
                            scope['user'] = user
                            print(f"DEBUG ASGI (WS): DRF Token ile kullanıcı doğrulandı: {user.username}")
                        else:
                            print(f"DEBUG ASGI (WS): DRF Token geçerli ama kullanıcı aktif değil: {user.username}")
                    except Token.DoesNotExist:
                        print(f"DEBUG ASGI (WS): DRF Token veritabanında bulunamadı: {token_key[:5]}...")
                    except Exception as drf_error:
                        print(f"DEBUG ASGI (WS): DRF Token doğrulama hatası: {drf_error}")
            else:
                print("DEBUG ASGI (WS): Sorgu parametrelerinde 'token' bulunamadı.")

        return await self.app(scope, receive, send)


# Ana ASGI uygulaması
print("DEBUG: asgi.py yüklendi - HTTP ve WS Token Doğrulamalı")

# WebSocket URL desenlerini import et
try:
    import chat.routing
    print("DEBUG ASGI: chat.routing import edildi")
except Exception as e:
    print(f"DEBUG ASGI: chat.routing import hatası: {e}")

try:
    import notifications.routing
    print("DEBUG ASGI: notifications.routing import edildi")
except Exception as e:
    print(f"DEBUG ASGI: notifications.routing import hatası: {e}")

# Render.com için WebSocket konfigürasyonu
all_websocket_patterns = []

try:
    # Chat routing'i ekle
    if hasattr(chat, 'routing') and hasattr(chat.routing, 'websocket_urlpatterns'):
        all_websocket_patterns.extend(chat.routing.websocket_urlpatterns)
        print(f"DEBUG ASGI: Chat routing eklendi: {len(chat.routing.websocket_urlpatterns)} pattern")
    
    # Notifications routing'i ekle
    if hasattr(notifications, 'routing') and hasattr(notifications.routing, 'websocket_urlpatterns'):
        all_websocket_patterns.extend(notifications.routing.websocket_urlpatterns)
        print(f"DEBUG ASGI: Notifications routing eklendi: {len(notifications.routing.websocket_urlpatterns)} pattern")
    
    print(f"DEBUG ASGI: Toplam WebSocket patterns: {len(all_websocket_patterns)}")
    
    # Her pattern'i ayrı ayrı yazdır
    for i, pattern in enumerate(all_websocket_patterns):
        print(f"DEBUG ASGI: Pattern {i}: {pattern}")
        
except Exception as e:
    print(f"DEBUG ASGI: WebSocket patterns oluşturma hatası: {e}")
    all_websocket_patterns = []

application = ProtocolTypeRouter({
    "http": django_asgi_app,  # HTTP için Django'nun kendi authentication'ını kullan
    "websocket": AuthTokenMiddleware(
        URLRouter(all_websocket_patterns)
    ),
})