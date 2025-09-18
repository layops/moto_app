from django.db import models
from django.contrib.auth import get_user_model
from django.contrib.contenttypes.fields import GenericForeignKey
from django.contrib.contenttypes.models import ContentType

User = get_user_model()

class Notification(models.Model):
    NOTIFICATION_TYPES = (
        ('message', 'Yeni Mesaj'),
        ('group_invite', 'Grup Daveti'),
        ('group_join_request', 'Grup Katılım İsteği'),
        ('group_join_approved', 'Grup Katılım Onaylandı'),
        ('group_join_rejected', 'Grup Katılım Reddedildi'),
        ('event_join_request', 'Etkinlik Katılım İsteği'),
        ('event_join_approved', 'Etkinlik Katılım Onaylandı'),
        ('event_join_rejected', 'Etkinlik Katılım Reddedildi'),
        ('ride_request', 'Yolculuk Katılım İsteği'),
        ('ride_update', 'Yolculuk Güncellemesi'),
        ('group_update', 'Grup Güncellemesi'),
        ('friend_request', 'Arkadaşlık İsteği'),
        ('follow', 'Takip Bildirimi'),
        ('like', 'Beğeni Bildirimi'),
        ('comment', 'Yorum Bildirimi'),
        ('test', 'Test Bildirimi'),
        ('other', 'Diğer'),
    )

    recipient = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='notifications',
        verbose_name='Alıcı'
    )
    sender = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        related_name='sent_notifications',
        null=True,
        blank=True,
        verbose_name='Gönderici'
    )
    message = models.TextField(verbose_name='Mesaj')
    notification_type = models.CharField(
        max_length=50,
        choices=NOTIFICATION_TYPES,
        default='other',
        verbose_name='Bildirim Türü'
    )
    content_type = models.ForeignKey(
        ContentType,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        verbose_name='İçerik Türü'
    )
    object_id = models.PositiveIntegerField(
        null=True,
        blank=True,
        verbose_name='Nesne ID'
    )
    content_object = GenericForeignKey('content_type', 'object_id')
    is_read = models.BooleanField(default=False, verbose_name='Okundu mu?')
    timestamp = models.DateTimeField(auto_now_add=True, verbose_name='Zaman Damgası')

    class Meta:
        ordering = ['-timestamp']
        verbose_name = 'Bildirim'
        verbose_name_plural = 'Bildirimler'

    def __str__(self):
        return f"Bildirim: {self.notification_type} - Alıcı: {self.recipient.username}"


class NotificationPreferences(models.Model):
    """Kullanıcıların bildirim tercihlerini saklar"""
    
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='notification_preferences',
        verbose_name='Kullanıcı'
    )
    
    # Messages
    direct_messages = models.BooleanField(default=True, verbose_name='Doğrudan Mesajlar')
    group_messages = models.BooleanField(default=True, verbose_name='Grup Mesajları')
    
    # Social
    likes_comments = models.BooleanField(default=True, verbose_name='Beğeni ve Yorumlar')
    follows = models.BooleanField(default=True, verbose_name='Takip Bildirimleri')
    
    # Events
    ride_reminders = models.BooleanField(default=True, verbose_name='Sürüş Hatırlatmaları')
    event_updates = models.BooleanField(default=True, verbose_name='Etkinlik Güncellemeleri')
    
    # Groups
    group_activity = models.BooleanField(default=True, verbose_name='Grup Aktivitesi')
    new_members = models.BooleanField(default=True, verbose_name='Yeni Üyeler')
    
    # Gamification
    challenges_rewards = models.BooleanField(default=True, verbose_name='Meydan Okumalar ve Ödüller')
    leaderboard_updates = models.BooleanField(default=True, verbose_name='Liderlik Tablosu Güncellemeleri')
    
    # Sound & Vibration
    sound_enabled = models.BooleanField(default=True, verbose_name='Ses Açık')
    vibration_enabled = models.BooleanField(default=True, verbose_name='Titreşim Açık')
    
    # Push notification settings
    push_enabled = models.BooleanField(default=True, verbose_name='Push Bildirimleri Açık')
    fcm_token = models.TextField(blank=True, null=True, verbose_name='FCM Token')
    
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='Oluşturulma Tarihi')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='Güncellenme Tarihi')

    class Meta:
        verbose_name = 'Bildirim Tercihi'
        verbose_name_plural = 'Bildirim Tercihleri'

    def __str__(self):
        return f"{self.user.username} - Bildirim Tercihleri"
    
    def get_preferences_dict(self):
        """Tercihleri dictionary olarak döndürür"""
        return {
            'direct_messages': self.direct_messages,
            'group_messages': self.group_messages,
            'likes_comments': self.likes_comments,
            'follows': self.follows,
            'ride_reminders': self.ride_reminders,
            'event_updates': self.event_updates,
            'group_activity': self.group_activity,
            'new_members': self.new_members,
            'challenges_rewards': self.challenges_rewards,
            'leaderboard_updates': self.leaderboard_updates,
            'sound_enabled': self.sound_enabled,
            'vibration_enabled': self.vibration_enabled,
            'push_enabled': self.push_enabled,
        }