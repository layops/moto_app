-- Supabase Database Webhook Setup Script
-- Bu script Supabase Dashboard'da manuel olarak çalıştırılmalıdır

-- 1. Notifications tablosu için webhook oluştur
-- Supabase Dashboard > Database > Webhooks > Create new hook

-- Webhook Configuration:
-- Table: notifications_notification
-- Events: Insert
-- Type: Supabase Edge Functions
-- Function: push
-- Method: POST
-- Timeout: 1000ms
-- HTTP Headers: Add auth header with service key

-- 2. Webhook'u test etmek için notifications tablosuna test verisi ekle
INSERT INTO notifications_notification (
    recipient_id,
    message,
    notification_type,
    is_read,
    timestamp
) VALUES (
    1, -- Test user ID (gerçek user ID ile değiştirin)
    'Test Supabase push notification',
    'test',
    false,
    NOW()
);

-- 3. Webhook'un çalışıp çalışmadığını kontrol et
-- Supabase Dashboard > Edge Functions > push function logs'u kontrol et

-- 4. Notification preferences'ları kontrol et
SELECT 
    np.user_id,
    np.push_enabled,
    np.direct_messages,
    np.group_messages,
    np.likes_comments,
    np.follows
FROM notifications_notificationpreferences np
WHERE np.user_id = 1; -- Test user ID'nizi yazın

-- 5. Webhook'u aktif etmek için Supabase Dashboard'da:
-- Database > Webhooks > Create new hook
-- Table: notifications_notification
-- Events: Insert
-- Type: Supabase Edge Functions
-- Function: push
-- Method: POST
-- Timeout: 1000ms
-- HTTP Headers: Add auth header with service key
-- Content-Type: application/json

-- 6. Edge Function'ı deploy etmek için:
-- supabase functions deploy push
-- FCM gerekli değil - Supabase real-time kullanılıyor
