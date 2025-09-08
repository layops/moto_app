from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import PrivateMessageViewSet, ConversationViewSet

router = DefaultRouter()
router.register(r'private-messages', PrivateMessageViewSet, basename='private-messages')
router.register(r'conversations', ConversationViewSet, basename='conversations')

urlpatterns = [
    path('', include(router.urls)),
]
