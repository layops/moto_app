# groups/serializers.py
from rest_framework import serializers
from .models import Group
from users.serializers import UserSerializer # Kullanıcı serileştiriciniz varsa

class GroupSerializer(serializers.ModelSerializer):
    # Grubun sahibi ve üyeleri için sadece ID veya temel bilgileri gösterebiliriz
    owner = serializers.ReadOnlyField(source='owner.username') # Sadece kullanıcı adını göster
    members = serializers.SlugRelatedField(
        many=True,
        read_only=True,
        slug_field='username' # Üyelerin sadece kullanıcı adlarını göster
    )

    class Meta:
        model = Group
        fields = ['id', 'name', 'description', 'owner', 'members', 'created_at']
        read_only_fields = ['owner', 'members', 'created_at'] # Bu alanlar POST/PUT ile doğrudan ayarlanmaz

class GroupMemberSerializer(serializers.Serializer):
    # Üye ekleme/çıkarma için kullanılacak bir serileştirici
    username = serializers.CharField(max_length=150)