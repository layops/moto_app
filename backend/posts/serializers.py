# moto_app/backend/posts/serializers.py

from rest_framework import serializers
from .models import Post
from users.serializers import UserSerializer
from groups.models import Group

class PostSerializer(serializers.ModelSerializer):
    author = UserSerializer(read_only=True)
    group = serializers.PrimaryKeyRelatedField(queryset=Group.objects.all(), required=False)

    class Meta:
        model = Post
        fields = ['id', 'group', 'author', 'content', 'created_at', 'updated_at']
        read_only_fields = ('id', 'author', 'created_at', 'updated_at')

    def create(self, validated_data):
        return super().create(validated_data)

    # BURAYI EKLEYİN: to_representation metodu
    def to_representation(self, instance):
        # Varsayılan temsili al
        representation = super().to_representation(instance)
        
        # Eğer view'dan 'only_content' bağlamı True olarak gelirse
        if self.context.get('only_content'):
            return representation.get('content') # Sadece 'content' alanını döndür
        return representation # Aksi takdirde tüm temsili döndür