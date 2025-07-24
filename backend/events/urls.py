# moto_app/backend/events/urls.py

from django.urls import path
from .views import EventListCreateView, EventDetailView

urlpatterns = [
    # Bir gruba ait tüm etkinlikleri listele ve yeni etkinlik oluştur
    # URL yapısı: /api/groups/<group_pk>/events/
    # Bu URL'ler groups.urls'den dahil edilecek
    path('', EventListCreateView.as_view(), name='event-list-create'),
    # Tek bir etkinliğin detayını gör, güncelle veya sil
    # URL yapısı: /api/groups/<group_pk>/events/<pk>/
    path('<int:pk>/', EventDetailView.as_view(), name='event-detail'),
]