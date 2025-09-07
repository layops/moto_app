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
        # Author alanını validated_data'dan çıkar (read_only olduğu için)
        author = validated_data.pop('author', None)
        post = super().create(validated_data)
        
        # Author'ı manuel olarak set et
        if author:
            post.author = author
            post.save()
            print(f"PostSerializer - Author manuel olarak set edildi: {author.username}")
        
        return post

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
        print(f"  - Author ID: {instance.author.id}")
        print(f"  - Representation author: {representation.get('author')}")
        if representation.get('author'):
            author_data = representation.get('author')
            print(f"  - Author data type: {type(author_data)}")
            if isinstance(author_data, dict):
                print(f"  - Author username in data: {author_data.get('username')}")
                print(f"  - Author ID in data: {author_data.get('id')}")
        
        # Eğer image_url varsa, image alanını None yap (frontend'de karışıklık olmasın)
        if instance.image_url:
            representation['image'] = None
        
        # Author verisini manuel olarak kontrol et
        if not representation.get('author') or not representation['author'].get('username'):
            print(f"PostSerializer - Author verisi eksik, manuel olarak ekleniyor")
            representation['author'] = {
                'id': instance.author.id,
                'username': instance.author.username,
                'email': instance.author.email,
                'profile_photo_url': None,  # Şimdilik None
            }
            print(f"PostSerializer - Manuel author verisi: {representation['author']}")
        
        return representation
