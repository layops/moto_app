#!/bin/bash

# Supabase Push Notification Deployment Script
# Bu script Supabase Edge Function'ı deploy eder ve gerekli konfigürasyonları yapar

echo "🚀 Supabase Push Notification Deployment Başlatılıyor..."

# 1. Supabase CLI kontrolü
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI bulunamadı. Lütfen önce Supabase CLI'yi yükleyin:"
    echo "npm install -g supabase"
    exit 1
fi

# 2. Supabase projesine bağlan
echo "📡 Supabase projesine bağlanılıyor..."
supabase link --project-ref $SUPABASE_PROJECT_REF

# 3. Edge Function'ı deploy et
echo "📦 Edge Function deploy ediliyor..."
supabase functions deploy push

# 4. FCM Server Key'i set et
if [ -z "$FCM_SERVER_KEY" ]; then
    echo "⚠️ FCM_SERVER_KEY environment variable bulunamadı"
    echo "Lütfen FCM_SERVER_KEY'i set edin:"
    echo "export FCM_SERVER_KEY=your_fcm_server_key"
    echo "supabase secrets set FCM_SERVER_KEY=your_fcm_server_key"
else
    echo "🔑 FCM Server Key set ediliyor..."
    supabase secrets set FCM_SERVER_KEY=$FCM_SERVER_KEY
fi

# 5. Deployment tamamlandı
echo "✅ Supabase Push Notification deployment tamamlandı!"
echo ""
echo "📋 Sonraki adımlar:"
echo "1. Supabase Dashboard > Database > Webhooks > Create new hook"
echo "2. Table: notifications, Events: Insert"
echo "3. Type: Supabase Edge Functions, Function: push"
echo "4. Method: POST, Timeout: 1000ms"
echo "5. HTTP Headers: Add auth header with service key"
echo ""
echo "🧪 Test için:"
echo "INSERT INTO notifications_notification (recipient_id, message, notification_type, is_read, timestamp) VALUES (1, 'Test notification', 'test', false, NOW());"
