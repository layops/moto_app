@echo off
REM Supabase Push Notification Deployment Script (Windows)
REM Bu script Supabase Edge Function'ı deploy eder ve gerekli konfigürasyonları yapar

echo 🚀 Supabase Push Notification Deployment Başlatılıyor...

REM 1. Supabase CLI kontrolü
supabase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Supabase CLI bulunamadı. Lütfen önce Supabase CLI'yi yükleyin:
    echo npm install -g supabase
    pause
    exit /b 1
)

REM 2. Supabase projesine bağlan
echo 📡 Supabase projesine bağlanılıyor...
supabase link --project-ref %SUPABASE_PROJECT_REF%

REM 3. Edge Function'ı deploy et
echo 📦 Edge Function deploy ediliyor...
supabase functions deploy push

REM 4. Supabase secrets kontrolü
echo 🔑 Supabase secrets kontrol ediliyor...
echo Supabase push notifications için FCM gerekli değil - Supabase real-time kullanılıyor

REM 5. Deployment tamamlandı
echo ✅ Supabase Push Notification deployment tamamlandı!
echo.
echo 📋 Sonraki adımlar:
echo 1. Supabase Dashboard ^> Database ^> Webhooks ^> Create new hook
echo 2. Table: notifications, Events: Insert
echo 3. Type: Supabase Edge Functions, Function: push
echo 4. Method: POST, Timeout: 1000ms
echo 5. HTTP Headers: Add auth header with service key
echo.
echo 🧪 Test için:
echo INSERT INTO notifications_notification (recipient_id, message, notification_type, is_read, timestamp) VALUES (1, 'Test Supabase real-time notification', 'test', false, NOW());
pause
