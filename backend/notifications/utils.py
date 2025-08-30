from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
from django.contrib.contenttypes.models import ContentType
from django.contrib.auth import get_user_model
from .models import Notification
from .serializers import NotificationSerializer

User = get_user_model()

def send_realtime_notification(recipient_user, message, notification_type='other', sender_user=None, content_object=None):
    notification = Notification.objects.create(
        recipient=recipient_user,
        sender=sender_user,
        message=message,
        notification_type=notification_type,
        content_type=ContentType.objects.get_for_model(content_object) if content_object else None,
        object_id=content_object.pk if content_object else None,
        is_read=False
    )

    serialized_notification = NotificationSerializer(notification).data
    channel_layer = get_channel_layer()
    group_name = f'user_notifications_{recipient_user.id}'
    async_to_sync(channel_layer.group_send)(group_name, {
        'type': 'send_notification',
        'notification': serialized_notification,
    })
