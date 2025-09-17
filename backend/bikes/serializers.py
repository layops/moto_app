# moto_app/backend/bikes/serializers.py

from rest_framework import serializers
from .models import Bike
from django.contrib.auth import get_user_model # User modelini import et

User = get_user_model() # User modelini al

class BikeSerializer(serializers.ModelSerializer):
    # 'owner' alanını kullanıcı adını gösterecek şekilde override ediyoruz
    owner = serializers.CharField(source='owner.username', read_only=True)
    # main_image field kaldırıldı, main_image_url kullanılıyor

    class Meta:
        model = Bike
        fields = [
            'id', 'owner', 'brand', 'model', 'year', 'engine_size', 
            'color', 'description', 'main_image_url', 'created_at', 'updated_at'
        ]
        read_only_fields = ('id', 'created_at', 'updated_at',)