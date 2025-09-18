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

def create_notifications_table_if_not_exists():
    """
    Supabase'de notifications tablosunu oluşturur (eğer yoksa)
    """
    try:
        client = get_supabase_client()
        
        # SQL ile tablo oluştur
        create_table_sql = """
        CREATE TABLE IF NOT EXISTS notifications (
            id SERIAL PRIMARY KEY,
            user_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            body TEXT NOT NULL,
            data JSONB DEFAULT '{}',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            is_read BOOLEAN DEFAULT FALSE
        );
        
        -- Index ekle
        CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
        CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);
        
        -- RLS (Row Level Security) aktif et
        ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
        
        -- Policy: Kullanıcılar sadece kendi bildirimlerini görebilir
        CREATE POLICY IF NOT EXISTS "Users can view own notifications" ON notifications
            FOR SELECT USING (auth.uid()::text = user_id::text);
            
        -- Policy: Sistem bildirim ekleyebilir
        CREATE POLICY IF NOT EXISTS "System can insert notifications" ON notifications
            FOR INSERT WITH CHECK (true);
        """
        
        # SQL'i çalıştır
        result = client.rpc('exec_sql', {'sql': create_table_sql}).execute()
        
        if result.data:
            logger.info("✅ Supabase notifications tablosu oluşturuldu/kontrol edildi")
            return True
        else:
            logger.error(f"❌ Supabase tablo oluşturma hatası: {result}")
            return False
            
    except Exception as e:
        logger.error(f"❌ Supabase tablo oluşturma hatası: {e}")
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
