from rest_framework import serializers
from .models import Group

class GroupSerializer(serializers.ModelSerializer):
    owner = UserSerializer(read_only=True)
    members = UserSerializer(many=True, read_only=True)
    
    class Meta:
        model = Group
        fields = ['id', 'name', 'description', 'owner', 'members', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']

class GroupMemberSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=150)
