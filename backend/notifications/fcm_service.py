"""
Firebase Cloud Messaging (FCM) Service
Push notification gönderme servisi
"""
import logging
import requests
import json
from django.conf import settings
from django.contrib.auth import get_user_model

User = get_user_model()
logger = logging.getLogger(__name__)

class FCMService:
    """Firebase Cloud Messaging servisi"""
    
    def __init__(self):
        self.server_key = getattr(settings, 'FCM_SERVER_KEY', None)
        self.fcm_url = 'https://fcm.googleapis.com/fcm/send'
        
        if not self.server_key:
            logger.warning("FCM_SERVER_KEY bulunamadı. Push notification gönderilemeyecek.")
    
    def send_notification(self, fcm_token, title, body, data=None):
        """
        FCM ile push notification gönder
        
        Args:
            fcm_token: Hedef cihazın FCM token'ı
            title: Bildirim başlığı
            body: Bildirim içeriği
            data: Ek veri (opsiyonel)
        """
        if not self.server_key:
            logger.error("FCM_SERVER_KEY bulunamadı")
            return False
            
        if not fcm_token:
            logger.error("FCM token bulunamadı")
            return False
        
        try:
            headers = {
                'Authorization': f'key={self.server_key}',
                'Content-Type': 'application/json'
            }
            
            payload = {
                'to': fcm_token,
                'notification': {
                    'title': title,
                    'body': body,
                    'sound': 'default',
                    'badge': 1
                },
                'data': data or {},
                'priority': 'high'
            }
            
            logger.info(f"📱 FCM notification gönderiliyor: {title}")
            
            response = requests.post(
                self.fcm_url,
                headers=headers,
                data=json.dumps(payload),
                timeout=10
            )
            
            if response.status_code == 200:
                result = response.json()
                if result.get('success', 0) > 0:
                    logger.info(f"✅ FCM notification başarıyla gönderildi: {title}")
                    return True
                else:
                    logger.error(f"❌ FCM notification başarısız: {result}")
                    return False
            else:
                logger.error(f"❌ FCM HTTP hatası: {response.status_code} - {response.text}")
                return False
                
        except Exception as e:
            logger.error(f"💥 FCM notification hatası: {e}")
            return False
    
    def send_to_multiple_tokens(self, fcm_tokens, title, body, data=None):
        """
        Birden fazla FCM token'a bildirim gönder
        
        Args:
            fcm_tokens: FCM token listesi
            title: Bildirim başlığı
            body: Bildirim içeriği
            data: Ek veri (opsiyonel)
        """
        if not self.server_key:
            logger.error("FCM_SERVER_KEY bulunamadı")
            return False
            
        if not fcm_tokens:
            logger.error("FCM token listesi boş")
            return False
        
        try:
            headers = {
                'Authorization': f'key={self.server_key}',
                'Content-Type': 'application/json'
            }
            
            payload = {
                'registration_ids': fcm_tokens,
                'notification': {
                    'title': title,
                    'body': body,
                    'sound': 'default',
                    'badge': 1
                },
                'data': data or {},
                'priority': 'high'
            }
            
            logger.info(f"📱 FCM bulk notification gönderiliyor: {len(fcm_tokens)} token - {title}")
            
            response = requests.post(
                self.fcm_url,
                headers=headers,
                data=json.dumps(payload),
                timeout=10
            )
            
            if response.status_code == 200:
                result = response.json()
                success_count = result.get('success', 0)
                failure_count = result.get('failure', 0)
                
                logger.info(f"✅ FCM bulk notification: {success_count} başarılı, {failure_count} başarısız")
                return success_count > 0
            else:
                logger.error(f"❌ FCM bulk HTTP hatası: {response.status_code} - {response.text}")
                return False
                
        except Exception as e:
            logger.error(f"💥 FCM bulk notification hatası: {e}")
            return False

# Global FCM service instance
fcm_service = FCMService()

def send_fcm_notification(user, title, body, data=None):
    """
    Kullanıcıya FCM push notification gönder
    
    Args:
        user: Hedef kullanıcı
        title: Bildirim başlığı
        body: Bildirim içeriği
        data: Ek veri (opsiyonel)
    """
    try:
        from .models import NotificationPreferences
        
        # Kullanıcının FCM token'ını al
        try:
            preferences = NotificationPreferences.objects.get(user=user)
            fcm_token = preferences.fcm_token
            
            if not fcm_token:
                logger.warning(f"FCM token bulunamadı: {user.username}")
                return False
                
            if not preferences.push_enabled:
                logger.info(f"Push notification kapalı: {user.username}")
                return False
                
        except NotificationPreferences.DoesNotExist:
            logger.warning(f"Notification preferences bulunamadı: {user.username}")
            return False
        
        # FCM notification gönder
        return fcm_service.send_notification(fcm_token, title, body, data)
        
    except Exception as e:
        logger.error(f"FCM notification gönderme hatası: {e}")
        return False

def send_fcm_notification_to_multiple_users(users, title, body, data=None):
    """
    Birden fazla kullanıcıya FCM push notification gönder
    
    Args:
        users: Hedef kullanıcı listesi
        title: Bildirim başlığı
        body: Bildirim içeriği
        data: Ek veri (opsiyonel)
    """
    try:
        from .models import NotificationPreferences
        
        # Kullanıcıların FCM token'larını al
        fcm_tokens = []
        for user in users:
            try:
                preferences = NotificationPreferences.objects.get(user=user)
                if preferences.fcm_token and preferences.push_enabled:
                    fcm_tokens.append(preferences.fcm_token)
            except NotificationPreferences.DoesNotExist:
                continue
        
        if not fcm_tokens:
            logger.warning("Hiçbir kullanıcıda geçerli FCM token bulunamadı")
            return False
        
        # FCM bulk notification gönder
        return fcm_service.send_to_multiple_tokens(fcm_tokens, title, body, data)
        
    except Exception as e:
        logger.error(f"FCM bulk notification gönderme hatası: {e}")
        return False