from django.urls import re_path
from . import consumers # chat/consumers.py dosyasındaki Consumer'ları import ediyoruz

websocket_urlpatterns = [
    # group_id ile bir sohbet odasına bağlanmak için URL deseni
    re_path(r'ws/chat/(?P<group_id>\d+)/$', consumers.ChatConsumer.as_asgi()),
]
