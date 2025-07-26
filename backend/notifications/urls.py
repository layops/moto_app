# moto_app/backend/notifications/urls.py

from django.urls import path
from .views import NotificationListView, NotificationMarkReadView, NotificationDeleteView

urlpatterns = [
    # Kullanıcının bildirimlerini listeleme
    # GET /api/notifications/
    # Okunmamışları filtrelemek için: GET /api/notifications/?is_read=false
    path('', NotificationListView.as_view(), name='notification-list'),

    # Bildirimleri okundu olarak işaretleme
    # PATCH /api/notifications/mark-read/
    path('mark-read/', NotificationMarkReadView.as_view(), name='notification-mark-read'),

    # Belirli bir bildirimi silme
    # DELETE /api/notifications/<id>/
    path('<int:pk>/', NotificationDeleteView.as_view(), name='notification-delete'),
]
