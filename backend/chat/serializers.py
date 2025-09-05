from rest_framework import serializers
from .models import PrivateMessage, GroupMessage
from users.serializers import UserSerializer

class PrivateMessageSerializer(serializers.ModelSerializer):
    sender = UserSerializer(read_only=True)
    receiver = UserSerializer(read_only=True)
    
    class Meta:
        model = PrivateMessage
        fields = [
            'id', 'sender', 'receiver', 'message', 'timestamp', 'is_read'
        ]
        read_only_fields = ['id', 'timestamp', 'sender']

class GroupMessageSerializer(serializers.ModelSerializer):
    sender = UserSerializer(read_only=True)
    group_name = serializers.CharField(source='group.name', read_only=True)
    reply_to_content = serializers.CharField(source='reply_to.content', read_only=True)
    
    class Meta:
        model = GroupMessage
        fields = [
            'id', 'group', 'group_name', 'sender', 'content', 'message_type',
            'file_url', 'reply_to', 'reply_to_content', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'sender']
