# Generated manually for test notification type

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('notifications', '0005_merge_0003_0004'),
    ]

    operations = [
        migrations.RunSQL(
            sql="ALTER TABLE notifications_notification ALTER COLUMN notification_type TYPE VARCHAR(50);",
            reverse_sql="ALTER TABLE notifications_notification ALTER COLUMN notification_type TYPE VARCHAR(50);",
        ),
    ]
