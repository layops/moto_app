from rest_framework import serializers
from .models import Ride
from django.conf import settings # AUTH_USER_MODEL için

class RideSerializer(serializers.ModelSerializer):
    # Katılımcıların sadece id'lerini veya kullanıcı adlarını göstermek isteyebiliriz
    # Örneğin, sadece kullanıcı adlarını göstermek için:
    participants = serializers.StringRelatedField(many=True, read_only=True)
    # veya kullanıcı bilgilerini daha detaylı göstermek istersen bir iç serileştirici kullanabiliriz.
    # Şimdilik StringRelatedField basit ve işlevsel olacaktır.

    owner = serializers.ReadOnlyField(source='owner.username') # Yolculuk sahibinin kullanıcı adını göster

    class Meta:
        model = Ride
        fields = [
            'id', 'owner', 'title', 'description', 'start_location',
            'end_location', 'start_time', 'end_time', 'participants',
            'max_participants', 'is_active', 'created_at', 'updated_at'
        ]
        read_only_fields = ('owner', 'created_at', 'updated_at', 'participants') # Bu alanlar API üzerinden direk değiştirilemez