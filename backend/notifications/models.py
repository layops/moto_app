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
