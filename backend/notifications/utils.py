import logging
import requests
import json
from django.conf import settings
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
from django.contrib.contenttypes.models import ContentType
from django.contrib.auth import get_user_model
from .models import Notification, NotificationPreferences
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
        # Çift bildirim kontrolü - son 5 dakika içinde aynı bildirim var mı?
        from django.utils import timezone
        from datetime import timedelta
        
        recent_time = timezone.now() - timedelta(minutes=5)
        
        # Aynı gönderici, alıcı, mesaj ve türde son 5 dakika içinde bildirim var mı?
        existing_notification = Notification.objects.filter(
            recipient=recipient_user,
            sender=sender_user,
            message=message,
            notification_type=notification_type,
            timestamp__gte=recent_time
        ).first()
        
        if existing_notification:
            logger.info(f"Çift bildirim engellendi: {recipient_user.username} - {notification_type}")
            return existing_notification
        
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


def send_fcm_notification(recipient_user, title, body, data=None, notification_type='other'):
    """
    Firebase Cloud Messaging ile push notification gönderir.
    
    Args:
        recipient_user: Bildirimi alacak kullanıcı
        title: Bildirim başlığı
        body: Bildirim içeriği
        data: Ek veri (opsiyonel)
        notification_type: Bildirim türü
    """
    try:
        # Kullanıcının notification preferences'ını kontrol et
        try:
            preferences = NotificationPreferences.objects.get(user=recipient_user)
            if not preferences.push_enabled:
                logger.info(f"Push notifications kapalı: {recipient_user.username}")
                return False
        except NotificationPreferences.DoesNotExist:
            # Preferences yoksa varsayılan olarak gönder
            pass
        
        # FCM token'ı al
        fcm_token = None
        try:
            preferences = NotificationPreferences.objects.get(user=recipient_user)
            fcm_token = preferences.fcm_token
        except NotificationPreferences.DoesNotExist:
            logger.warning(f"FCM token bulunamadı: {recipient_user.username}")
            return False
        
        if not fcm_token:
            logger.warning(f"FCM token boş: {recipient_user.username}")
            return False
        
        # Firebase Server Key (settings'den al)
        server_key = getattr(settings, 'FCM_SERVER_KEY', None)
        if not server_key:
            logger.error("FCM_SERVER_KEY bulunamadı")
            return False
        
        # FCM API endpoint
        url = 'https://fcm.googleapis.com/fcm/send'
        
        # Headers
        headers = {
            'Authorization': f'key={server_key}',
            'Content-Type': 'application/json',
        }
        
        # Payload
        payload = {
            'to': fcm_token,
            'notification': {
                'title': title,
                'body': body,
                'sound': 'default',
                'badge': 1,
            },
            'data': {
                'notification_type': notification_type,
                'user_id': str(recipient_user.id),
                'username': recipient_user.username,
                **(data or {}),
            },
            'priority': 'high',
        }
        
        # Request gönder
        response = requests.post(url, headers=headers, data=json.dumps(payload))
        
        if response.status_code == 200:
            result = response.json()
            if result.get('success') == 1:
                logger.info(f"FCM bildirim gönderildi: {recipient_user.username}")
                return True
            else:
                logger.error(f"FCM bildirim hatası: {result}")
                return False
        else:
            logger.error(f"FCM API hatası: {response.status_code} - {response.text}")
            return False
            
    except Exception as e:
        logger.error(f"FCM bildirim gönderme hatası: {e}")
        return False


def send_notification_with_preferences(recipient_user, message, notification_type='other', sender_user=None, content_object=None, title=None):
    """
    Kullanıcının tercihlerine göre bildirim gönderir (WebSocket + FCM).
    
    Args:
        recipient_user: Bildirimi alacak kullanıcı
        message: Bildirim mesajı
        notification_type: Bildirim türü
        sender_user: Bildirimi gönderen kullanıcı (opsiyonel)
        content_object: İlgili nesne (opsiyonel)
        title: FCM için başlık (opsiyonel)
    """
    try:
        # Kullanıcının notification preferences'ını al
        try:
            preferences = NotificationPreferences.objects.get(user=recipient_user)
        except NotificationPreferences.DoesNotExist:
            # Preferences yoksa varsayılan tercihlerle oluştur
            preferences = NotificationPreferences.objects.create(user=recipient_user)
        
        # Notification type'a göre tercih kontrolü
        should_send = False
        
        if notification_type == 'message':
            should_send = preferences.direct_messages
        elif notification_type == 'group_message':
            should_send = preferences.group_messages
        elif notification_type in ['ride_request', 'ride_update']:
            should_send = preferences.ride_reminders
        elif notification_type in ['event_update', 'event_join_request', 'event_join_approved', 'event_join_rejected']:
            should_send = preferences.event_updates
        elif notification_type in ['group_update', 'group_invite']:
            should_send = preferences.group_activity
        elif notification_type == 'group_join_request':
            should_send = preferences.new_members
        elif notification_type in ['challenge', 'reward']:
            should_send = preferences.challenges_rewards
        elif notification_type == 'leaderboard_update':
            should_send = preferences.leaderboard_updates
        else:
            should_send = True  # Diğer türler için varsayılan olarak gönder
        
        if not should_send:
            logger.info(f"Bildirim tercihi kapalı: {recipient_user.username} - {notification_type}")
            return None
        
        # WebSocket bildirimi gönder
        notification = send_realtime_notification(
            recipient_user=recipient_user,
            message=message,
            notification_type=notification_type,
            sender_user=sender_user,
            content_object=content_object
        )
        
        # FCM push notification gönder
        if preferences.push_enabled and preferences.fcm_token:
            fcm_title = title or f"MotoApp - {notification_type.replace('_', ' ').title()}"
            send_fcm_notification(
                recipient_user=recipient_user,
                title=fcm_title,
                body=message,
                data={
                    'notification_id': str(notification.id) if notification else None,
                    'sender_username': sender_user.username if sender_user else None,
                },
                notification_type=notification_type
            )
        
        return notification
        
    except Exception as e:
        logger.error(f"Tercihli bildirim gönderme hatası: {e}")
        raise
