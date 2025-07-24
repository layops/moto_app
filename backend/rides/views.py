# moto_app/backend/rides/views.py

from rest_framework import viewsets, permissions
from .models import Ride
from .serializers import RideSerializer
from .permissions import IsOwnerOrReadOnly # Yeni izin sınıfımızı import et
from django.db.models import Q # Arama ve filtreleme için ileride kullanılabilir

class RideViewSet(viewsets.ModelViewSet):
    queryset = Ride.objects.all()
    serializer_class = RideSerializer
    permission_classes = [IsOwnerOrReadOnly] # Yeni iznimizi kullan

    def perform_create(self, serializer):
        # Yeni bir yolculuk oluşturulurken, owner'ı isteği yapan kullanıcı olarak ayarla
        serializer.save(owner=self.request.user)

    # İleride buraya özel filtreleme, arama veya katılımcı ekleme/çıkarma mantığı eklenebilir.
    def get_queryset(self):
        # Varsayılan queryset'i al
        queryset = super().get_queryset() # Önce base ModelViewSet'in queryset'ini al

        # URL'deki sorgu parametrelerinden 'start_location' değerini al
        # Örneğin: /api/rides/?start_location=Istanbul
        start_location = self.request.query_params.get('start_location')

        # Eğer 'start_location' parametresi varsa, queryset'i filtrele
        if start_location:
            # start_location alanına göre filtreleme yap
            # __iexact: büyük/küçük harf duyarsız tam eşleşme (örn: 'istanbul' veya 'Istanbul' çalışır)
            # Eğer konumlar veritabanında daha karmaşık bir yapıda ise (örn: GeoDjango), filtreleme mantığı değişebilir.
            queryset = queryset.filter(start_location__iexact=start_location)
        
        return queryset

    # İleride buraya özel filtreleme, arama veya katılımcı ekleme/çıkarma mantığı eklenebilir.
