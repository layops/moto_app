from rest_framework import serializers
from .models import Group, GroupJoinRequest, GroupMessage
from users.serializers import UserSerializer
from django.contrib.auth import get_user_model

User = get_user_model()

class GroupSerializer(serializers.ModelSerializer):
    owner = UserSerializer(read_only=True)
    members = UserSerializer(many=True, read_only=True)
    moderators = UserSerializer(many=True, read_only=True)
    member_count = serializers.ReadOnlyField()
    is_public = serializers.ReadOnlyField()
    
    class Meta:
        model = Group
        fields = [
            'id', 'name', 'description', 'join_type', 'profile_picture_url', 
            'max_members', 'member_count', 'is_public', 'owner', 'members', 
            'moderators', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'member_count', 'is_public']

class GroupMemberSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'profile_picture']

class GroupJoinRequestSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    group = GroupSerializer(read_only=True)
    responded_by = UserSerializer(read_only=True)
    
    class Meta:
        model = GroupJoinRequest
        fields = [
            'id', 'group', 'user', 'message', 'status', 
            'requested_at', 'responded_at', 'responded_by'
        ]
        read_only_fields = ['id', 'requested_at', 'responded_at', 'responded_by']

class GroupJoinRequestCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = GroupJoinRequest
        fields = ['message']

class GroupMessageSerializer(serializers.ModelSerializer):
    sender = UserSerializer(read_only=True)
    reply_to = serializers.SerializerMethodField()
    
    class Meta:
        model = GroupMessage
        fields = [
            'id', 'group', 'sender', 'content', 'message_type', 
            'file_url', 'reply_to', 'is_edited', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'is_edited']
    
    def get_reply_to(self, obj):
        if obj.reply_to:
            return {
                'id': obj.reply_to.id,
                'content': obj.reply_to.content[:100],
                'sender': UserSerializer(obj.reply_to.sender).data
            }
        return None

class GroupMessageCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = GroupMessage
        fields = ['content', 'message_type', 'file_url', 'reply_to']