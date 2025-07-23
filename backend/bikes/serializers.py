# moto_app/backend/bikes/serializers.py

from rest_framework import serializers
from .models import Bike
from django.contrib.auth import get_user_model # User modelini import et

User = get_user_model() # User modelini al

class BikeSerializer(serializers.ModelSerializer):
    # 'owner' alanını kullanıcı adını gösterecek şekilde override ediyoruz
    owner = serializers.CharField(source='owner.username', read_only=True)

    class Meta:
        model = Bike
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at',) # owner artık burada belirtildiği için kaldırıldı