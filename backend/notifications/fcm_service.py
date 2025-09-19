"""
Firebase Cloud Messaging (FCM) Service
Push notification gönderme servisi
"""
import os
import logging
from django.conf import settings
from django.contrib.auth import get_user_model
import requests

User = get_user_model()
logger = logging.getLogger(__name__)

def send_fcm_notification(user, title, body, data=None, image_url=None):
    """
    FCM ile push notification gönderir
    
    Args:
        user: Bildirimi alacak kullanıcı
        title: Bildirim başlığı
        body: Bildirim içeriği
        data: Ek veri (dict)
        image_url: Resim URL'i (opsiyonel)
    
    Returns:
        bool: Başarılı olup olmadığı
    """
    try:
        # Kullanıcının FCM token'ını al
        if not hasattr(user, 'fcm_token') or not user.fcm_token:
            logger.warning(f"❌ FCM token bulunamadı: {user.username}")
            return False
        
        fcm_token = user.fcm_token
        
        # FCM server key
        fcm_server_key = getattr(settings, 'FCM_SERVER_KEY', None)
        if not fcm_server_key:
            logger.error("❌ FCM_SERVER_KEY bulunamadı")
            return False
        
        # FCM API URL
        fcm_url = "https://fcm.googleapis.com/fcm/send"
        
        # Notification payload
        notification_payload = {
            "to": fcm_token,
            "notification": {
                "title": title,
                "body": body,
                "sound": "default",
                "badge": 1
            },
            "data": data or {},
            "priority": "high"
        }
        
        # Resim URL'i varsa ekle
        if image_url:
            notification_payload["notification"]["image"] = image_url
        
        # Headers
        headers = {
            "Authorization": f"key={fcm_server_key}",
            "Content-Type": "application/json"
        }
        
        logger.info(f"📱 FCM notification gönderiliyor: {user.username} - {title}")
        
        # FCM API'ye istek gönder
        response = requests.post(
            fcm_url,
            json=notification_payload,
            headers=headers,
            timeout=30
        )
        
        if response.status_code == 200:
            response_data = response.json()
            if response_data.get('success') == 1:
                logger.info(f"✅ FCM notification gönderildi: {user.username}")
                return True
            else:
                logger.error(f"❌ FCM API error: {response_data}")
                return False
        else:
            logger.error(f"❌ FCM HTTP error: {response.status_code} - {response.text}")
            return False
            
    except Exception as e:
        logger.error(f"💥 FCM notification hatası: {e}")
        return False

def send_bulk_fcm_notifications(users, title, body, data=None, image_url=None):
    """
    Birden fazla kullanıcıya FCM notification gönderir
    
    Args:
        users: Kullanıcı listesi
        title: Bildirim başlığı
        body: Bildirim içeriği
        data: Ek veri (dict)
        image_url: Resim URL'i (opsiyonel)
    
    Returns:
        dict: Başarılı/başarısız sayıları
    """
    results = {
        'success': 0,
        'failed': 0,
        'no_token': 0
    }
    
    for user in users:
        if not hasattr(user, 'fcm_token') or not user.fcm_token:
            results['no_token'] += 1
            continue
            
        success = send_fcm_notification(user, title, body, data, image_url)
        if success:
            results['success'] += 1
        else:
            results['failed'] += 1
    
    logger.info(f"📊 FCM bulk notification sonuçları: {results}")
    return results

def validate_fcm_token(token):
    """
    FCM token'ının geçerliliğini kontrol eder
    
    Args:
        token: FCM token
    
    Returns:
        bool: Geçerli olup olmadığı
    """
    try:
        if not token:
            return False
            
        # Basit format kontrolü
        if len(token) < 100:  # FCM token'lar genellikle uzun olur
            return False
            
        # FCM server key kontrolü
        fcm_server_key = getattr(settings, 'FCM_SERVER_KEY', None)
        if not fcm_server_key:
            return False
            
        return True
        
    except Exception as e:
        logger.error(f"💥 FCM token validation hatası: {e}")
        return False
