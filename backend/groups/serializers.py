from rest_framework import serializers
from .models import Group

class GroupSerializer(serializers.ModelSerializer):
    owner = serializers.ReadOnlyField(source='owner.username')
    members = serializers.SlugRelatedField(
        many=True,
        read_only=True,
        slug_field='username'
    )

    class Meta:
        model = Group
        fields = ['id', 'name', 'description', 'owner', 'members', 'created_at']
        read_only_fields = ['owner', 'members', 'created_at']

class GroupMemberSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=150)
