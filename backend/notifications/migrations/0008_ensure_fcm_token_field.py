# Generated manually to ensure fcm_token field exists

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('notifications', '0007_add_missing_notification_preferences_fields'),
    ]

    operations = [
        # Bu migration sadece fcm_token alanının var olduğundan emin olmak için
        # Eğer alan zaten varsa hiçbir şey yapmaz
        migrations.RunSQL(
            sql="""
                DO $$ 
                BEGIN
                    IF NOT EXISTS (
                        SELECT 1 FROM information_schema.columns 
                        WHERE table_name = 'notifications_notificationpreferences' 
                        AND column_name = 'fcm_token'
                    ) THEN
                        ALTER TABLE notifications_notificationpreferences 
                        ADD COLUMN fcm_token TEXT NULL;
                    END IF;
                END $$;
            """,
            reverse_sql="""
                ALTER TABLE notifications_notificationpreferences 
                DROP COLUMN IF EXISTS fcm_token;
            """
        ),
    ]
