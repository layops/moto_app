import logging
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
from django.contrib.contenttypes.models import ContentType
from django.contrib.auth import get_user_model
from .models import Notification
from .serializers import NotificationSerializer

User = get_user_model()
logger = logging.getLogger(__name__)

def send_realtime_notification(recipient_user, message, notification_type='other', sender_user=None, content_object=None):
    """
    Gerçek zamanlı bildirim gönderir ve veritabanına kaydeder.
    
    Args:
        recipient_user: Bildirimi alacak kullanıcı
        message: Bildirim mesajı
        notification_type: Bildirim türü
        sender_user: Bildirimi gönderen kullanıcı (opsiyonel)
        content_object: İlgili nesne (opsiyonel)
    """
    try:
        # Bildirimi veritabanına kaydet
        notification = Notification.objects.create(
            recipient=recipient_user,
            sender=sender_user,
            message=message,
            notification_type=notification_type,
            content_type=ContentType.objects.get_for_model(content_object) if content_object else None,
            object_id=content_object.pk if content_object else None,
            is_read=False
        )

        # WebSocket üzerinden gerçek zamanlı bildirim gönder
        serialized_notification = NotificationSerializer(notification).data
        channel_layer = get_channel_layer()
        group_name = f'user_notifications_{recipient_user.id}'
        
        async_to_sync(channel_layer.group_send)(group_name, {
            'type': 'send_notification',
            'notification': serialized_notification,
        })
        
        logger.info(f"Bildirim gönderildi: {recipient_user.username} - {notification_type}")
        
    except Exception as e:
        logger.error(f"Bildirim gönderme hatası: {e}")
        raise

def send_bulk_notifications(recipients, message, notification_type='other', sender_user=None, content_object=None):
    """
    Birden fazla kullanıcıya toplu bildirim gönderir.
    
    Args:
        recipients: Bildirimi alacak kullanıcılar listesi
        message: Bildirim mesajı
        notification_type: Bildirim türü
        sender_user: Bildirimi gönderen kullanıcı (opsiyonel)
        content_object: İlgili nesne (opsiyonel)
    """
    try:
        notifications = []
        for recipient in recipients:
            notification = Notification(
                recipient=recipient,
                sender=sender_user,
                message=message,
                notification_type=notification_type,
                content_type=ContentType.objects.get_for_model(content_object) if content_object else None,
                object_id=content_object.pk if content_object else None,
                is_read=False
            )
            notifications.append(notification)
        
        # Toplu kaydet
        created_notifications = Notification.objects.bulk_create(notifications)
        
        # Her kullanıcı için WebSocket bildirimi gönder
        channel_layer = get_channel_layer()
        for notification in created_notifications:
            # bulk_create sonrası ID'ler otomatik atanır
            serialized_notification = NotificationSerializer(notification).data
            group_name = f'user_notifications_{notification.recipient.id}'
            
            async_to_sync(channel_layer.group_send)(group_name, {
                'type': 'send_notification',
                'notification': serialized_notification,
            })
        
        logger.info(f"Toplu bildirim gönderildi: {len(recipients)} kullanıcı - {notification_type}")
        
    except Exception as e:
        logger.error(f"Toplu bildirim gönderme hatası: {e}")
        raise
