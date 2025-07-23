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