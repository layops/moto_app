# moto_app/backend/notifications/models.py

from django.db import models
from django.contrib.auth import get_user_model
from django.contrib.contenttypes.fields import GenericForeignKey
from django.contrib.contenttypes.models import ContentType

User = get_user_model()

class Notification(models.Model):
    # Bildirim türleri için sabitler
    NOTIFICATION_TYPES = (
        ('message', 'Yeni Mesaj'),
        ('group_invite', 'Grup Daveti'),
        ('ride_request', 'Yolculuk Katılım İsteği'),
        ('ride_update', 'Yolculuk Güncellemesi'),
        ('group_update', 'Grup Güncellemesi'),
        ('friend_request', 'Arkadaşlık İsteği'),
        ('other', 'Diğer'),
    )

    # Bildirimi alan kullanıcı (alıcı)
    recipient = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='notifications',
        verbose_name='Alıcı'
    )

    # Bildirimi tetikleyen kullanıcı (isteğe bağlı)
    sender = models.ForeignKey(
        User,
        on_delete=models.SET_NULL, # Gönderici silinse bile bildirim kalır
        related_name='sent_notifications',
        null=True,
        blank=True,
        verbose_name='Gönderici'
    )

    # Bildirim mesajı
    message = models.TextField(verbose_name='Mesaj')

    # Bildirim türü (yukarıdaki sabitlerden biri)
    notification_type = models.CharField(
        max_length=50,
        choices=NOTIFICATION_TYPES,
        default='other',
        verbose_name='Bildirim Türü'
    )

    # Bildirimin ilgili olduğu nesne (GenericForeignKey ile esneklik)
    # Hangi modelle ilişkili olduğunu tutar (örneğin: PrivateMessage, Group, Ride)
    content_type = models.ForeignKey(
        ContentType,
        on_delete=models.CASCADE,
        null=True,    # <-- BU SATIRI EKLEYİN
        blank=True,   # <-- BU SATIRI EKLEYİN
        verbose_name='İçerik Türü'
    )
    # İlgili nesnenin ID'sini tutar
    object_id = models.PositiveIntegerField(
        null=True,    # <-- BU SATIRI EKLEYİN
        blank=True,   # <-- BU SATIRI EKLEYİN
        verbose_name='Nesne ID'
    )
    # content_type ve object_id'yi birleştiren alan
    content_object = GenericForeignKey('content_type', 'object_id')

    # Bildirimin okunup okunmadığı
    is_read = models.BooleanField(default=False, verbose_name='Okundu mu?')

    # Bildirimin oluşturulma zamanı
    timestamp = models.DateTimeField(auto_now_add=True, verbose_name='Zaman Damgası')

    class Meta:
        ordering = ['-timestamp'] # En yeni bildirimler en üstte
        verbose_name = 'Bildirim'
        verbose_name_plural = 'Bildirimler'

    def __str__(self):
        return f"Bildirim: {self.notification_type} - Alıcı: {self.recipient.username}"

