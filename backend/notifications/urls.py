from django.urls import path
from .views import NotificationListView, NotificationMarkReadView, NotificationDeleteView, SendTestNotificationView

urlpatterns = [
    path('', NotificationListView.as_view(), name='notification-list'),
    path('mark-read/', NotificationMarkReadView.as_view(), name='notification-mark-read'),
    path('<int:pk>/', NotificationDeleteView.as_view(), name='notification-delete'),
    path('send_test_notification/', SendTestNotificationView.as_view(), name='send-test-notification'),
]
