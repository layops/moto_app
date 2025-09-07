# posts/serializers.py

from rest_framework import serializers
from .models import Post
from users.serializers import UserSerializer
from groups.models import Group

class PostSerializer(serializers.ModelSerializer):
    author = UserSerializer(read_only=True)  # Nested serializer ile detaylı user bilgisi
    group = serializers.PrimaryKeyRelatedField(queryset=Group.objects.all(), required=False)
    image = serializers.ImageField(required=False, write_only=True)  # Sadece yazma için, okuma için değil
    content = serializers.CharField(required=True, allow_blank=False)  # Content zorunlu ve boş olamaz

    class Meta:
        model = Post
        fields = [
            'id', 'group', 'author', 'content', 'image', 'image_url', 'created_at', 'updated_at'
        ]
        read_only_fields = ('id', 'author', 'created_at', 'updated_at')

    def create(self, validated_data):
        return super().create(validated_data)

    def to_representation(self, instance):
        """
        Eğer context'te 'only_content' flag'i varsa sadece content dön.
        Aksi halde tüm alanları dön.
        """
        representation = super().to_representation(instance)
        if self.context.get('only_content'):
            return representation.get('content')
        
        # Debug log'ları
        print(f"PostSerializer - Post {instance.id}:")
        print(f"  - Author: {instance.author}")
        print(f"  - Author username: {instance.author.username}")
        print(f"  - Representation author: {representation.get('author')}")
        
        # Eğer image_url varsa, image alanını None yap (frontend'de karışıklık olmasın)
        if instance.image_url:
            representation['image'] = None
        
        return representation
