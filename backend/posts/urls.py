from django.urls import path
from .views import PostListCreateView, PostDetailView

urlpatterns = [
    # Bir gruba ait tüm gönderileri listele ve yeni gönderi oluştur
    # URL yapısı: /api/groups/<group_pk>/posts/
    # Bu URL'ler groups.urls'den dahil edilecek
    path('', PostListCreateView.as_view(), name='post-list-create'),
    # Tek bir gönderinin detayını gör, güncelle veya sil
    # URL yapısı: /api/groups/<group_pk>/posts/<pk>/
    path('<int:pk>/', PostDetailView.as_view(), name='post-detail'),
]