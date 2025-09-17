from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import PrivateMessageViewSet, ConversationViewSet, RoomMessagesView

router = DefaultRouter()
router.register(r'private-messages', PrivateMessageViewSet, basename='private-messages')
router.register(r'conversations', ConversationViewSet, basename='conversations')

urlpatterns = [
    path('', include(router.urls)),
    # Frontend'in beklediği URL pattern
    path('rooms/private_<int:user1_id>_<int:user2_id>/messages/', RoomMessagesView.as_view(), name='room-messages'),
]
