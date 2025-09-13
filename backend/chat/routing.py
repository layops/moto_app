# moto_app/backend/chat/routing.py

from django.urls import re_path
# chat/consumers.py dosyasındaki Consumer'ları import ediyoruz
from . import consumers 

websocket_urlpatterns = [
    # Genel grup sohbeti için URL deseni
    re_path(r'^ws/chat/(?P<group_id>\d+)/$', consumers.ChatConsumer.as_asgi()),
    
    # Özel mesajlaşma için URL deseni
    # Örneğin: ws://localhost:8000/ws/private_chat/1/2/ (Kullanıcı 1 ve Kullanıcı 2 arasında)
    re_path(r'^ws/private_chat/(?P<user1_id>\d+)/(?P<user2_id>\d+)/$', consumers.PrivateChatConsumer.as_asgi()),
]

# Bu dosya yüklendiğinde URL desenlerini yazdır
print(f"DEBUG ROUTING: chat/routing.py yüklendi. websocket_urlpatterns: {websocket_urlpatterns}")
