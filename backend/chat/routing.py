# moto_app/backend/chat/routing.py

from django.urls import re_path
# chat/consumers.py dosyasındaki Consumer'ları import ediyoruz
from . import consumers 
# notifications/consumers.py dosyasındaki NotificationConsumer'ı import ediyoruz
from notifications import consumers as notification_consumers 

websocket_urlpatterns = [
    # Genel grup sohbeti için URL deseni
    re_path(r'ws/chat/(?P<group_id>\d+)/$', consumers.ChatConsumer.as_asgi()),
    
    # Özel mesajlaşma için URL deseni
    # Örneğin: ws://localhost:8000/ws/private_chat/1/2/ (Kullanıcı 1 ve Kullanıcı 2 arasında)
    re_path(r'ws/private_chat/(?P<user1_id>\d+)/(?P<user2_id>\d+)/$', consumers.PrivateChatConsumer.as_asgi()),

    # Kullanıcıya özel bildirimler için WebSocket URL deseni (BU SATIR SADECE BİR KEZ OLMALI VE BAŞKA KOPYASI OLMAMALI)
    # Örneğin: ws://localhost:8000/ws/notifications/?token=<kullanici_tokeni>
    re_path(r'ws/notifications/$', notification_consumers.NotificationConsumer.as_asgi()),
]

# Bu dosya yüklendiğinde URL desenlerini yazdır
print(f"DEBUG ROUTING: chat/routing.py yüklendi. websocket_urlpatterns: {websocket_urlpatterns}")
