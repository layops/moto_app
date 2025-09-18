from rest_framework import serializers
from .models import Notification, NotificationPreferences
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


class NotificationPreferencesSerializer(serializers.ModelSerializer):
    class Meta:
        model = NotificationPreferences
        fields = [
            'direct_messages',
            'group_messages',
            'likes_comments',
            'follows',
            'ride_reminders',
            'event_updates',
            'group_activity',
            'new_members',
            'challenges_rewards',
            'leaderboard_updates',
            'sound_enabled',
            'vibration_enabled',
            'push_enabled',
            # 'fcm_token', # FCM kaldırıldı - Supabase push notifications kullanılıyor
        ]
        read_only_fields = ['created_at', 'updated_at']


# FCM Token Serializer kaldırıldı - Supabase push notifications kullanılıyor
# class FCMTokenSerializer(serializers.Serializer):
#     fcm_token = serializers.CharField(max_length=1000, required=True)
