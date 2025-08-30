from rest_framework import serializers
from .models import Notification
from users.serializers import UserSerializer

class NotificationSerializer(serializers.ModelSerializer):
    sender = UserSerializer(read_only=True)
    recipient = UserSerializer(read_only=True)
    content_object_type = serializers.CharField(source='content_type.model', read_only=True)
    content_object_id = serializers.IntegerField(source='object_id', read_only=True)

    class Meta:
        model = Notification
        fields = [
            'id',
            'recipient',
            'sender',
            'message',
            'notification_type',
            'content_object_type',
            'content_object_id',
            'is_read',
            'timestamp',
        ]
        read_only_fields = fields

class NotificationMarkReadSerializer(serializers.Serializer):
    notification_ids = serializers.ListField(
        child=serializers.IntegerField(),
        min_length=1,
        write_only=True
    )
