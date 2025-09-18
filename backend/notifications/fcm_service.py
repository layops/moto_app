"""
Firebase Cloud Messaging (FCM) Service
Push notification gönderme servisi
"""
import requests
import json
import logging
from django.conf import settings
from typing import List, Dict, Optional

logger = logging.getLogger(__name__)

class FCMService:
    """FCM push notification servisi"""
    
    FCM_URL = "https://fcm.googleapis.com/fcm/send"
    
    def __init__(self):
        self.server_key = getattr(settings, 'FCM_SERVER_KEY', None)
        if not self.server_key:
            logger.warning("FCM_SERVER_KEY bulunamadı. Push notification gönderilemeyecek.")
    
    def send_notification(
        self, 
        fcm_token: str, 
        title: str, 
        body: str, 
        data: Optional[Dict] = None,
        notification_type: str = 'other'
    ) -> bool:
        """
        Tek bir FCM token'a push notification gönderir
        
        Args:
            fcm_token: Hedef cihazın FCM token'ı
            title: Bildirim başlığı
            body: Bildirim içeriği
            data: Ek veri (opsiyonel)
            notification_type: Bildirim türü
            
        Returns:
            bool: Başarılı ise True, başarısız ise False
        """
        if not self.server_key:
            logger.error("FCM server key bulunamadı")
            return False
            
        if not fcm_token:
            logger.error("FCM token bulunamadı")
            return False
        
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
            'data': {
                'notification_type': notification_type,
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                **(data or {})
            },
            'priority': 'high',
            'time_to_live': 3600  # 1 saat
        }
        
        try:
            response = requests.post(
                self.FCM_URL, 
                headers=headers, 
                data=json.dumps(payload),
                timeout=10
            )
            
            if response.status_code == 200:
                result = response.json()
                if result.get('success', 0) > 0:
                    logger.info(f"FCM push notification gönderildi: {title}")
                    return True
                else:
                    logger.error(f"FCM gönderme hatası: {result}")
                    return False
            else:
                logger.error(f"FCM HTTP hatası: {response.status_code} - {response.text}")
                return False
                
        except requests.exceptions.RequestException as e:
            logger.error(f"FCM istek hatası: {e}")
            return False
        except Exception as e:
            logger.error(f"FCM genel hatası: {e}")
            return False
    
    def send_multicast_notification(
        self, 
        fcm_tokens: List[str], 
        title: str, 
        body: str, 
        data: Optional[Dict] = None,
        notification_type: str = 'other'
    ) -> Dict[str, int]:
        """
        Birden fazla FCM token'a push notification gönderir
        
        Args:
            fcm_tokens: Hedef cihazların FCM token'ları listesi
            title: Bildirim başlığı
            body: Bildirim içeriği
            data: Ek veri (opsiyonel)
            notification_type: Bildirim türü
            
        Returns:
            Dict: {'success': int, 'failure': int}
        """
        if not self.server_key:
            logger.error("FCM server key bulunamadı")
            return {'success': 0, 'failure': len(fcm_tokens)}
            
        if not fcm_tokens:
            logger.error("FCM token listesi boş")
            return {'success': 0, 'failure': 0}
        
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
            'data': {
                'notification_type': notification_type,
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                **(data or {})
            },
            'priority': 'high',
            'time_to_live': 3600  # 1 saat
        }
        
        try:
            response = requests.post(
                self.FCM_URL, 
                headers=headers, 
                data=json.dumps(payload),
                timeout=10
            )
            
            if response.status_code == 200:
                result = response.json()
                success_count = result.get('success', 0)
                failure_count = result.get('failure', 0)
                
                logger.info(f"FCM multicast gönderildi: {success_count} başarılı, {failure_count} başarısız")
                
                # Başarısız token'ları logla
                if 'results' in result:
                    for i, token_result in enumerate(result['results']):
                        if 'error' in token_result:
                            logger.warning(f"FCM token hatası: {fcm_tokens[i]} - {token_result['error']}")
                
                return {'success': success_count, 'failure': failure_count}
            else:
                logger.error(f"FCM multicast HTTP hatası: {response.status_code} - {response.text}")
                return {'success': 0, 'failure': len(fcm_tokens)}
                
        except requests.exceptions.RequestException as e:
            logger.error(f"FCM multicast istek hatası: {e}")
            return {'success': 0, 'failure': len(fcm_tokens)}
        except Exception as e:
            logger.error(f"FCM multicast genel hatası: {e}")
            return {'success': 0, 'failure': len(fcm_tokens)}

# Global FCM service instance
fcm_service = FCMService()

def send_fcm_notification(fcm_token: str, title: str, body: str, data: Optional[Dict] = None, notification_type: str = 'other') -> bool:
    """FCM push notification gönderir"""
    return fcm_service.send_notification(fcm_token, title, body, data, notification_type)

def send_fcm_multicast(fcm_tokens: List[str], title: str, body: str, data: Optional[Dict] = None, notification_type: str = 'other') -> Dict[str, int]:
    """Birden fazla FCM token'a push notification gönderir"""
    return fcm_service.send_multicast_notification(fcm_tokens, title, body, data, notification_type)
