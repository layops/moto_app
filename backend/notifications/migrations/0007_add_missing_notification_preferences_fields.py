# Generated manually to add missing NotificationPreferences fields

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('notifications', '0006_add_test_notification_type'),
    ]

    operations = [
        # Bu migration Supabase SQL editörde manuel olarak çalıştırıldı
        # Veritabanı değişiklikleri add_missing_notification_preferences_columns.sql dosyasında
        migrations.RunSQL("SELECT 1;"),  # Fake operation - sadece migration state'i güncellemek için
    ]
