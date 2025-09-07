from rest_framework import serializers
from .models import Post
from users.serializers import UserSerializer

class PostSerializer(serializers.ModelSerializer):
    author = UserSerializer(read_only=True)
    author_username = serializers.CharField(source='author.username', read_only=True)
    group_name = serializers.CharField(source='group.name', read_only=True)

    class Meta:
        model = Post
        fields = [
            'id', 'author', 'author_username', 'group', 'group_name', 
            'content', 'image_url', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'author']

