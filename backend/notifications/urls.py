from django.urls import path
from .views import (
    NotificationListView, 
    NotificationMarkReadView, 
    NotificationDeleteView, 
    SendTestNotificationView,
    NotificationPreferencesView,
    FCMTokenView,
    SupabaseTestView
)
from .sse_views import notification_stream

urlpatterns = [
    path('', NotificationListView.as_view(), name='notification-list'),
    path('mark-read/', NotificationMarkReadView.as_view(), name='notification-mark-read'),
    path('<int:pk>/', NotificationDeleteView.as_view(), name='notification-delete'),
    path('send_test_notification/', SendTestNotificationView.as_view(), name='send-test-notification'),
    path('test/', SendTestNotificationView.as_view(), name='test-notification'),  # GET için basit test
    path('stream/', notification_stream, name='notification-stream'),
    path('preferences/', NotificationPreferencesView.as_view(), name='notification-preferences'),
    path('fcm-token/', FCMTokenView.as_view(), name='fcm-token'),
    path('supabase-test/', SupabaseTestView.as_view(), name='supabase-test'),
]
