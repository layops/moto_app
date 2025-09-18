# Generated manually to create NotificationPreferences model

from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('notifications', '0002_alter_notification_content_type_and_more'),
    ]

    operations = [
        # Table already exists in database - this migration is marked as fake
        # migrations.CreateModel(
        #     name='NotificationPreferences',
        #     fields=[
        #         ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
        #         ('direct_messages', models.BooleanField(default=True, verbose_name='Doğrudan Mesajlar')),
        #         ('group_messages', models.BooleanField(default=True, verbose_name='Grup Mesajları')),
        #         ('likes_comments', models.BooleanField(default=True, verbose_name='Beğeni ve Yorumlar')),
        #         ('follows', models.BooleanField(default=True, verbose_name='Takip Bildirimleri')),
        #         ('ride_reminders', models.BooleanField(default=True, verbose_name='Sürüş Hatırlatmaları')),
        #         ('event_updates', models.BooleanField(default=True, verbose_name='Etkinlik Güncellemeleri')),
        #         ('group_activity', models.BooleanField(default=True, verbose_name='Grup Aktivitesi')),
        #         ('new_members', models.BooleanField(default=True, verbose_name='Yeni Üyeler')),
        #         ('challenges_rewards', models.BooleanField(default=True, verbose_name='Meydan Okumalar ve Ödüller')),
        #         ('leaderboard_updates', models.BooleanField(default=True, verbose_name='Liderlik Tablosu Güncellemeleri')),
        #         ('sound_enabled', models.BooleanField(default=True, verbose_name='Ses Açık')),
        #         ('vibration_enabled', models.BooleanField(default=True, verbose_name='Titreşim Açık')),
        #         ('push_enabled', models.BooleanField(default=True, verbose_name='Push Bildirimleri Açık')),
        #         ('fcm_token', models.TextField(blank=True, null=True, verbose_name='FCM Token')),
        #         ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Oluşturulma Tarihi')),
        #         ('updated_at', models.DateTimeField(auto_now=True, verbose_name='Güncellenme Tarihi')),
        #         ('user', models.OneToOneField(on_delete=models.deletion.CASCADE, related_name='notification_preferences', to=settings.AUTH_USER_MODEL, verbose_name='Kullanıcı')),
        #     ],
        #     options={
        #         'verbose_name': 'Bildirim Tercihi',
        #         'verbose_name_plural': 'Bildirim Tercihleri',
        #     },
        # ),
    ]
