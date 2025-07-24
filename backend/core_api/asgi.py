import os
from django.core.asgi import get_asgi_application
from channels.routing import ProtocolTypeRouter, URLRouter
from urllib.parse import parse_qs

# Django ortamını yükle
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core_api.settings')
django_asgi_app = get_asgi_application()

# Özel Kimlik Doğrulama Middleware'i
class AuthTokenMiddleware:
    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope['type'] == 'websocket':
            query_string = scope.get('query_string', b'').decode('utf-8')
            query_params = parse_qs(query_string)
            token_key_list = query_params.get('token')

            from django.contrib.auth.models import AnonymousUser
            from asgiref.sync import sync_to_async
            from django.contrib.auth import get_user_model
            User = get_user_model()

            scope['user'] = AnonymousUser()

            if token_key_list:
                token_key = token_key_list[0]
                print(f"DEBUG ASGI: Sorgu dizesinden token bulundu. Token başlangıcı: {token_key[:5]}...")

                # Token'dan user döndüren senkron fonksiyon
                @sync_to_async
                def get_user_from_token(key):
                    from rest_framework.authtoken.models import Token
                    return Token.objects.get(key=key).user

                try:
                    user = await get_user_from_token(token_key)
                    if user.is_active:
                        scope['user'] = user
                        print(f"DEBUG ASGI: Kullanıcı doğrulandı: {user.username} (ID: {user.id})")
                    else:
                        print(f"DEBUG ASGI: Token geçerli, ancak kullanıcı aktif değil: {user.username}")
                except Exception as e:
                    print(f"DEBUG ASGI: Token doğrulamada beklenmeyen hata: {e}")
            else:
                print("DEBUG ASGI: Sorgu dizesinde 'token' bulunamadı.")

        return await self.app(scope, receive, send)

# Ana ASGI uygulaması tanımı
print("DEBUG: asgi.py dosyası yüklendi - Versiyon 20250724_2")
import chat.routing

print(f"DEBUG ASGI: Yönlendiriciye verilen URL desenleri: {chat.routing.websocket_urlpatterns}")

application = ProtocolTypeRouter({
    "http": django_asgi_app,
    "websocket": AuthTokenMiddleware(
        URLRouter(
            chat.routing.websocket_urlpatterns
        )
    ),
})
