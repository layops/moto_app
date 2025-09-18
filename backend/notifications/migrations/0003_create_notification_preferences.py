# Generated manually to create NotificationPreferences model

from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('notifications', '0002_alter_notification_content_type_and_more'),
    ]

    operations = [
        migrations.CreateModel(
            name='NotificationPreferences',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('direct_messages', models.BooleanField(default=True, verbose_name='Doğrudan Mesajlar')),
                ('group_messages', models.BooleanField(default=True, verbose_name='Grup Mesajları')),
                ('user', models.OneToOneField(on_delete=models.deletion.CASCADE, related_name='notification_preferences', to=settings.AUTH_USER_MODEL, verbose_name='Kullanıcı')),
            ],
            options={
                'verbose_name': 'Bildirim Tercihi',
                'verbose_name_plural': 'Bildirim Tercihleri',
            },
        ),
    ]
