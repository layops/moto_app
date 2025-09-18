-- Supabase Database Webhook Setup Script
-- Bu script Supabase Dashboard'da manuel olarak çalıştırılmalıdır

-- 1. Notifications tablosu için webhook oluştur
-- Supabase Dashboard > Database > Webhooks > Create new hook

-- Webhook Configuration:
-- Table: notifications
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

-- 4. FCM token'ların doğru kaydedildiğini kontrol et
SELECT 
    np.user_id,
    u.username,
    np.fcm_token,
    np.push_enabled
FROM notifications_notificationpreferences np
JOIN auth_user u ON np.user_id = u.id
WHERE np.fcm_token IS NOT NULL;

-- 5. Webhook'u aktif etmek için Supabase Dashboard'da:
-- Database > Webhooks > Create new hook
-- Table: notifications
-- Events: Insert
-- Type: Supabase Edge Functions
-- Function: push
-- Method: POST
-- Timeout: 1000ms
-- HTTP Headers: Add auth header with service key
-- Content-Type: application/json

-- 6. Edge Function'ı deploy etmek için:
-- supabase functions deploy push
-- supabase secrets set FCM_SERVER_KEY=your_fcm_server_key
