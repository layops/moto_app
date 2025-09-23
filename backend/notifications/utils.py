from django.contrib.auth import get_user_model
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
from .models import Notification, NotificationPreferences
from .serializers import NotificationSerializer
import logging

User = get_user_model()
logger = logging.getLogger(__name__)

def send_realtime_notification(recipient_user, message, notification_type='other', sender_user=None, content_object=None):
    """
    Gerçek zamanlı bildirim gönderir (WebSocket + Database).
    
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
            content_object=content_object
        )

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
    for recipient in recipients:
        try:
            send_realtime_notification(
                recipient_user=recipient,
                message=message,
                notification_type=notification_type,
                sender_user=sender_user,
                content_object=content_object
            )
        except Exception as e:
            logger.error(f"Toplu bildirim hatası - {recipient.username}: {e}")

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
        except Exception as e:
            # FCM token alanı eksikse geçici olarak varsayılan tercihler kullan
            logger.warning(f"NotificationPreferences alınamadı (FCM token alanı eksik olabilir): {e}")
            # Geçici olarak varsayılan değerlerle devam et
            class TempPreferences:
                def __init__(self):
                    self.direct_messages = True
                    self.group_messages = True
                    self.likes_comments = True
                    self.follows = True
                    self.ride_reminders = True
                    self.event_updates = True
                    self.group_activity = True
                    self.new_members = True
                    self.challenges_rewards = True
                    self.leaderboard_updates = True
                    self.push_enabled = False  # FCM token yoksa push notification'ı kapat
            preferences = TempPreferences()
        
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
        # Hata olsa bile WebSocket bildirimini göndermeye çalış
        try:
            return send_realtime_notification(
                recipient_user=recipient_user,
                message=message,
                notification_type=notification_type,
                sender_user=sender_user,
                content_object=content_object
            )
        except Exception as fallback_error:
            logger.error(f"Fallback bildirim hatası: {fallback_error}")
            return None

def send_group_invite_notification(recipient_user, group_name, sender_user):
    """Grup daveti bildirimi gönderir."""
    try:
        message = f"{sender_user.get_full_name() or sender_user.username} sizi '{group_name}' grubuna davet etti"
        notification = send_notification_with_preferences(
            recipient_user=recipient_user,
            message=message,
            notification_type='group_invite',
            sender_user=sender_user,
            title=f"Grup Daveti - {group_name}"
        )
        logger.info(f"Grup daveti bildirimi gönderildi: {recipient_user.username} - {group_name}")
        return notification
    except Exception as e:
        logger.error(f"Grup daveti bildirimi hatası: {e}")
        return None

def send_ride_request_notification(recipient_user, ride_title, sender_user):
    """Yolculuk katılım isteği bildirimi gönderir."""
    try:
        message = f"{sender_user.get_full_name() or sender_user.username} '{ride_title}' yolculuğuna katılmak istiyor"
        notification = send_notification_with_preferences(
            recipient_user=recipient_user,
            message=message,
            notification_type='ride_request',
            sender_user=sender_user,
            title=f"Yolculuk Katılım İsteği - {ride_title}"
        )
        logger.info(f"Yolculuk isteği bildirimi gönderildi: {recipient_user.username} - {ride_title}")
        return notification
    except Exception as e:
        logger.error(f"Yolculuk isteği bildirimi hatası: {e}")
        return None

def send_event_join_request_notification(recipient_user, event_title, sender_user):
    """Etkinlik katılım isteği bildirimi gönderir."""
    try:
        message = f"{sender_user.get_full_name() or sender_user.username} '{event_title}' etkinliğine katılmak istiyor"
        notification = send_notification_with_preferences(
            recipient_user=recipient_user,
            message=message,
            notification_type='event_join_request',
            sender_user=sender_user,
            title=f"Etkinlik Katılım İsteği - {event_title}"
        )
        logger.info(f"Etkinlik isteği bildirimi gönderildi: {recipient_user.username} - {event_title}")
        return notification
    except Exception as e:
        logger.error(f"Etkinlik isteği bildirimi hatası: {e}")
        return None

def send_follow_notification(recipient_user, sender_user):
    """Takip bildirimi gönderir."""
    try:
        message = f"{sender_user.get_full_name() or sender_user.username} sizi takip etmeye başladı"
        notification = send_notification_with_preferences(
            recipient_user=recipient_user,
            message=message,
            notification_type='follow',
            sender_user=sender_user,
            title="Yeni Takipçi"
        )
        logger.info(f"Takip bildirimi gönderildi: {recipient_user.username} - {sender_user.username}")
        return notification
    except Exception as e:
        logger.error(f"Takip bildirimi hatası: {e}")
        return None

def send_like_notification(recipient_user, content_type, sender_user):
    """Beğeni bildirimi gönderir."""
    try:
        content_name = "içeriği" if content_type == "post" else "yorumu"
        message = f"{sender_user.get_full_name() or sender_user.username} {content_name} beğendi"
        notification = send_notification_with_preferences(
            recipient_user=recipient_user,
            message=message,
            notification_type='like',
            sender_user=sender_user,
            title="Yeni Beğeni"
        )
        logger.info(f"Beğeni bildirimi gönderildi: {recipient_user.username} - {sender_user.username}")
        return notification
    except Exception as e:
        logger.error(f"Beğeni bildirimi hatası: {e}")
        return None

def send_comment_notification(recipient_user, content_type, sender_user):
    """Yorum bildirimi gönderir."""
    try:
        content_name = "içeriğinize" if content_type == "post" else "yorumunuza"
        message = f"{sender_user.get_full_name() or sender_user.username} {content_name} yorum yaptı"
        notification = send_notification_with_preferences(
            recipient_user=recipient_user,
            message=message,
            notification_type='comment',
            sender_user=sender_user,
            title="Yeni Yorum"
        )
        logger.info(f"Yorum bildirimi gönderildi: {recipient_user.username} - {sender_user.username}")
        return notification
    except Exception as e:
        logger.error(f"Yorum bildirimi hatası: {e}")
        return None