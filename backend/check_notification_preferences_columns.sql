-- NotificationPreferences tablosundaki mevcut sütunları kontrol et
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'notifications_notificationpreferences'
ORDER BY ordinal_position;
