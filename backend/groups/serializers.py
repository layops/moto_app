from rest_framework import serializers
from .models import Group
from users.serializers import UserSerializer
from django.contrib.auth import get_user_model

User = get_user_model()

class GroupSerializer(serializers.ModelSerializer):
    owner = UserSerializer(read_only=True)
    members = UserSerializer(many=True, read_only=True)
    member_count = serializers.ReadOnlyField()
    is_public = serializers.ReadOnlyField()
    
    class Meta:
        model = Group
        fields = [
            'id', 'name', 'description', 'profile_picture_url', 
            'member_count', 'is_public', 'owner', 'members', 
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'member_count', 'is_public']

class GroupMemberSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'profile_picture']