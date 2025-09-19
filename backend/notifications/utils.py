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
from .supabase_client import send_realtime_notification_via_supabase, send_supabase_push_notification

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
        logger.info(f"🔔 Bildirim gönderiliyor: {recipient_user.username} - {notification_type} - {message[:50]}...")
        
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
            logger.info(f"⚠️ Çift bildirim engellendi: {recipient_user.username} - {notification_type}")
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
        
        logger.info(f"✅ Bildirim veritabanına kaydedildi: ID {notification.id}")

        # WebSocket üzerinden gerçek zamanlı bildirim gönder
        try:
            serialized_notification = NotificationSerializer(notification).data
            channel_layer = get_channel_layer()
            group_name = f'user_notifications_{recipient_user.id}'
            
            logger.info(f"📡 WebSocket bildirimi gönderiliyor: {group_name}")
            
            async_to_sync(channel_layer.group_send)(group_name, {
                'type': 'send_notification',
                'notification': serialized_notification,
            })
            
            logger.info(f"✅ WebSocket bildirimi gönderildi: {recipient_user.username} - {notification_type}")
        except Exception as e:
            logger.error(f"❌ WebSocket bildirimi hatası: {e}")
        
        logger.info(f"🎉 Bildirim başarıyla gönderildi: {recipient_user.username} - {notification_type}")
        
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




def send_notification_with_preferences(recipient_user, message, notification_type='other', sender_user=None, content_object=None, title=None):
    """
    Kullanıcının tercihlerine göre bildirim gönderir (WebSocket + FCM Push).
    
    Args:
        recipient_user: Bildirimi alacak kullanıcı
        message: Bildirim mesajı
        notification_type: Bildirim türü
        sender_user: Bildirimi gönderen kullanıcı (opsiyonel)
        content_object: İlgili nesne (opsiyonel)
        title: Push notification için başlık (opsiyonel)
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
        elif notification_type in ['like', 'comment']:
            should_send = preferences.likes_comments
        elif notification_type == 'follow':
            should_send = preferences.follows
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
        logger.info(f"🔔 FCM push notification kontrolü: {recipient_user.username} - push_enabled: {preferences.push_enabled}")
        
        if preferences.push_enabled:
            try:
                push_title = title or f"MotoApp - {notification_type.replace('_', ' ').title()}"
                push_data = {
                    'notification_id': str(notification.id),
                    'sender_id': str(sender_user.id) if sender_user else None,
                    'sender_username': sender_user.username if sender_user else None,
                    'notification_type': notification_type,
                }
                
                # FCM push notification gönder
                logger.info(f"📱 FCM push notification gönderiliyor: {recipient_user.username} - {push_title}")
                
                from .fcm_service import send_fcm_notification
                fcm_success = send_fcm_notification(
                    user=recipient_user,
                    title=push_title,
                    body=message,
                    data=push_data
                )
                
                if fcm_success:
                    logger.info(f"✅ FCM push notification gönderildi: {recipient_user.username} - {push_title}")
                else:
                    logger.warning(f"❌ FCM push notification gönderilemedi: {recipient_user.username}")
                    
            except Exception as e:
                logger.error(f"💥 FCM push notification hatası: {e}")
        else:
            logger.info(f"🚫 FCM push notification gönderilmedi - tercihler kapalı: {recipient_user.username}")
        
        return notification
        
    except Exception as e:
        logger.error(f"Tercihli bildirim gönderme hatası: {e}")


def send_follow_notification(follower_user, followed_user):
    """
    Takip bildirimi gönderir - hem WebSocket hem de push notification
    
    Args:
        follower_user: Takip eden kullanıcı
        followed_user: Takip edilen kullanıcı
    """
    try:
        message = f"{follower_user.username} sizi takip etmeye başladı!"
        notification_type = 'follow'
        
        # Takip bildirimi gönder (WebSocket + Push notification)
        notification = send_notification_with_preferences(
            recipient_user=followed_user,
            message=message,
            notification_type=notification_type,
            sender_user=follower_user,
            title="Yeni Takipçi!"
        )
        
        if notification:
            logger.info(f"Takip bildirimi gönderildi: {follower_user.username} -> {followed_user.username}")
            return notification
        else:
            logger.warning(f"Takip bildirimi gönderilemedi: {follower_user.username} -> {followed_user.username}")
            return None
            
    except Exception as e:
        logger.error(f"Takip bildirimi hatası: {e}")
        return None


def send_like_notification(liker_user, post_owner, post_title=None):
    """
    Beğeni bildirimi gönderir
    
    Args:
        liker_user: Beğenen kullanıcı
        post_owner: Post sahibi
        post_title: Post başlığı (opsiyonel)
    """
    try:
        post_info = f" '{post_title}'" if post_title else ""
        message = f"{liker_user.username} gönderinizi{post_info} beğendi!"
        notification_type = 'like'
        
        notification = send_notification_with_preferences(
            recipient_user=post_owner,
            message=message,
            notification_type=notification_type,
            sender_user=liker_user,
            title="Gönderiniz Beğenildi!"
        )
        
        if notification:
            logger.info(f"Beğeni bildirimi gönderildi: {liker_user.username} -> {post_owner.username}")
            return notification
        else:
            logger.warning(f"Beğeni bildirimi gönderilemedi: {liker_user.username} -> {post_owner.username}")
            return None
            
    except Exception as e:
        logger.error(f"Beğeni bildirimi hatası: {e}")
        return None


def send_comment_notification(commenter_user, post_owner, post_title=None):
    """
    Yorum bildirimi gönderir
    
    Args:
        commenter_user: Yorum yapan kullanıcı
        post_owner: Post sahibi
        post_title: Post başlığı (opsiyonel)
    """
    try:
        post_info = f" '{post_title}'" if post_title else ""
        message = f"{commenter_user.username} gönderinize{post_info} yorum yaptı!"
        notification_type = 'comment'
        
        notification = send_notification_with_preferences(
            recipient_user=post_owner,
            message=message,
            notification_type=notification_type,
            sender_user=commenter_user,
            title="Gönderinize Yorum Yapıldı!"
        )
        
        if notification:
            logger.info(f"Yorum bildirimi gönderildi: {commenter_user.username} -> {post_owner.username}")
            return notification
        else:
            logger.warning(f"Yorum bildirimi gönderilemedi: {commenter_user.username} -> {post_owner.username}")
            return None
            
    except Exception as e:
        logger.error(f"Yorum bildirimi hatası: {e}")
        return None
