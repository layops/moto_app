# moto_app/backend/events/serializers.py

from rest_framework import serializers
from .models import Event
from groups.models import Group # Group modelini import et
from users.serializers import UserSerializer # Organizatör ve katılımcı bilgilerini göstermek için UserSerializer kullanacağız
from django.contrib.auth import get_user_model # AUTH_USER_MODEL'e erişmek için

User = get_user_model()

class EventSerializer(serializers.ModelSerializer):
    # Organizatör bilgisini sadece okunabilir ve UserSerializer ile göster
    organizer = UserSerializer(read_only=True)
    
    # Katılımcıları ID'leriyle alıp-göstermek için ManyToMany ilişkisini handle et
    # Hem okunabilir hem de yazılabilir olmalı
    participants = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.all(), 
        many=True, 
        required=False # Etkinlik oluştururken veya güncellerken zorunlu olmasın
    )
    
    # Grubu primary key olarak alacağız (URL'den gelecek)
    group = serializers.PrimaryKeyRelatedField(
        queryset=Group.objects.all(), 
        required=False # Bu alan view içinde otomatik atanacak
    )

    class Meta:
        model = Event
        fields = [
            'id', 'group', 'organizer', 'title', 'description', 
            'location', 'start_time', 'end_time', 'participants', 
            'created_at', 'updated_at'
        ]
        read_only_fields = ('id', 'organizer', 'created_at', 'updated_at') # Bu alanlar otomatik doldurulacak

    # Etkinlik oluşturulurken veya güncellenirken ek mantık gerekebilir (örn. katılımcılar)
    def create(self, validated_data):
        # Eğer katılımcılar validated_data içinde gelirse onları ayır
        participants_data = validated_data.pop('participants', [])
        
        # Event objesini oluştur
        event = super().create(validated_data)
        
        # Katılımcıları ekle
        event.participants.set(participants_data) # set() metodu mevcut ilişkileri silip yenilerini ekler
        
        return event

    def update(self, instance, validated_data):
        # Katılımcılar güncelleniyorsa
        participants_data = validated_data.pop('participants', None)

        # Diğer alanları güncelle
        instance = super().update(instance, validated_data)

        # Eğer katılımcı verisi geldiyse, ilişkileri güncelle
        if participants_data is not None:
            instance.participants.set(participants_data)
        
        return instance