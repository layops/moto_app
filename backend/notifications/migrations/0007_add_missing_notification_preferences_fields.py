# Generated manually to add missing NotificationPreferences fields

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('notifications', '0006_add_test_notification_type'),
    ]

    operations = [
        migrations.AddField(
            model_name='notificationpreferences',
            name='likes_comments',
            field=models.BooleanField(default=True, verbose_name='Beğeni ve Yorumlar'),
        ),
        migrations.AddField(
            model_name='notificationpreferences',
            name='follows',
            field=models.BooleanField(default=True, verbose_name='Takip Bildirimleri'),
        ),
        migrations.AddField(
            model_name='notificationpreferences',
            name='ride_reminders',
            field=models.BooleanField(default=True, verbose_name='Sürüş Hatırlatmaları'),
        ),
        migrations.AddField(
            model_name='notificationpreferences',
            name='event_updates',
            field=models.BooleanField(default=True, verbose_name='Etkinlik Güncellemeleri'),
        ),
        migrations.AddField(
            model_name='notificationpreferences',
            name='group_activity',
            field=models.BooleanField(default=True, verbose_name='Grup Aktivitesi'),
        ),
        migrations.AddField(
            model_name='notificationpreferences',
            name='new_members',
            field=models.BooleanField(default=True, verbose_name='Yeni Üyeler'),
        ),
        migrations.AddField(
            model_name='notificationpreferences',
            name='challenges_rewards',
            field=models.BooleanField(default=True, verbose_name='Meydan Okumalar ve Ödüller'),
        ),
        migrations.AddField(
            model_name='notificationpreferences',
            name='leaderboard_updates',
            field=models.BooleanField(default=True, verbose_name='Liderlik Tablosu Güncellemeleri'),
        ),
        migrations.AddField(
            model_name='notificationpreferences',
            name='sound_enabled',
            field=models.BooleanField(default=True, verbose_name='Ses Açık'),
        ),
        migrations.AddField(
            model_name='notificationpreferences',
            name='vibration_enabled',
            field=models.BooleanField(default=True, verbose_name='Titreşim Açık'),
        ),
        migrations.AddField(
            model_name='notificationpreferences',
            name='push_enabled',
            field=models.BooleanField(default=True, verbose_name='Push Bildirimleri Açık'),
        ),
        migrations.AddField(
            model_name='notificationpreferences',
            name='fcm_token',
            field=models.TextField(blank=True, null=True, verbose_name='FCM Token'),
        ),
        migrations.AddField(
            model_name='notificationpreferences',
            name='created_at',
            field=models.DateTimeField(auto_now_add=True, verbose_name='Oluşturulma Tarihi'),
        ),
        migrations.AddField(
            model_name='notificationpreferences',
            name='updated_at',
            field=models.DateTimeField(auto_now=True, verbose_name='Güncellenme Tarihi'),
        ),
    ]
