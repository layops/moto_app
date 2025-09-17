"""
Supabase Client Utility
Supabase real-time notifications ve storage için client
"""
import os
import logging
from django.conf import settings
from supabase import create_client, Client

logger = logging.getLogger(__name__)

def get_supabase_client() -> Client:
    """
    Supabase client'ını döndürür
    """
    try:
        if not hasattr(settings, 'SUPABASE_URL') or not settings.SUPABASE_URL:
            raise ValueError("SUPABASE_URL bulunamadı")
        
        if not hasattr(settings, 'SUPABASE_ANON_KEY') or not settings.SUPABASE_ANON_KEY:
            raise ValueError("SUPABASE_ANON_KEY bulunamadı")
        
        client = create_client(settings.SUPABASE_URL, settings.SUPABASE_ANON_KEY)
        logger.info("Supabase client başarıyla oluşturuldu")
        return client
        
    except Exception as e:
        logger.error(f"Supabase client oluşturma hatası: {e}")
        raise

def send_realtime_notification_via_supabase(user_id: int, title: str, body: str, data: dict = None):
    """
    Supabase real-time ile bildirim gönderir
    """
    try:
        client = get_supabase_client()
        
        # Notifications tablosuna kaydet
        notification_data = {
            'user_id': user_id,
            'title': title,
            'body': body,
            'data': data or {},
            'created_at': 'now()'
        }
        
        result = client.table('notifications').insert(notification_data).execute()
        
        if result.data:
            logger.info(f"Supabase real-time bildirim gönderildi: user_id={user_id}")
            return True
        else:
            logger.error(f"Supabase bildirim gönderme hatası: {result}")
            return False
            
    except Exception as e:
        logger.error(f"Supabase real-time bildirim hatası: {e}")
        return False

def subscribe_to_notifications(user_id: int):
    """
    Kullanıcının bildirimlerine subscribe olur
    """
    try:
        client = get_supabase_client()
        
        # Real-time subscription
        subscription = client.table('notifications')\
            .on('INSERT', 
                lambda payload: logger.info(f"Yeni bildirim: {payload}")
            )\
            .subscribe()
        
        logger.info(f"Bildirim subscription başlatıldı: user_id={user_id}")
        return subscription
        
    except Exception as e:
        logger.error(f"Bildirim subscription hatası: {e}")
        return None
