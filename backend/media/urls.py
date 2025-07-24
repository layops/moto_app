from django.urls import path
from .views import MediaListCreateView, MediaDetailView # Media'nın views'ını import edin

urlpatterns = [
    # Bir gruba ait medya dosyalarını listeleme ve yeni medya dosyası oluşturma
    path('', MediaListCreateView.as_view(), name='media-list-create'),
    # Belirli bir medya dosyasının detaylarını görme, güncelleme veya silme
    path('<int:pk>/', MediaDetailView.as_view(), name='media-detail'),
]