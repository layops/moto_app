from django.urls import re_path
from . import consumers

websocket_urlpatterns = [
    re_path(r'ws/notifications/$', consumers.NotificationConsumer.as_asgi()),
]

# Debug için routing yüklendiğinde log yazdır
print(f"DEBUG ROUTING: notifications/routing.py yüklendi. websocket_urlpatterns: {websocket_urlpatterns}")