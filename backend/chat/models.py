from django.db import models
from django.conf import settings
from groups.models import Group

class PrivateMessage(models.Model):
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='sent_private_messages',
        verbose_name="Gönderen"
    )
    receiver = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='received_private_messages',
        verbose_name="Alıcı"
    )
    message = models.TextField(verbose_name="Mesaj İçeriği")
    timestamp = models.DateTimeField(auto_now_add=True, verbose_name="Zaman Damgası")
    is_read = models.BooleanField(default=False, verbose_name="Okundu Bilgisi")

    class Meta:
        ordering = ['timestamp']
        verbose_name = "Özel Mesaj"
        verbose_name_plural = "Özel Mesajlar"

    def __str__(self):
        return f"From {self.sender.username} to {self.receiver.username}: {self.message[:50]}..."

    def mark_as_read(self):
        if not self.is_read:
            self.is_read = True
            self.save()


class GroupMessage(models.Model):
    """Grup mesajları modeli"""
    MESSAGE_TYPES = [
        ('text', 'Metin'),
        ('image', 'Resim'),
        ('file', 'Dosya'),
    ]
    
    group = models.ForeignKey(
        Group,
        on_delete=models.CASCADE,
        related_name='messages',
        verbose_name="Grup"
    )
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='sent_group_messages',
        verbose_name="Gönderen"
    )
    content = models.TextField(verbose_name="Mesaj İçeriği")
    message_type = models.CharField(
        max_length=20,
        choices=MESSAGE_TYPES,
        default='text',
        verbose_name="Mesaj Türü"
    )
    file_url = models.URLField(blank=True, null=True, verbose_name="Dosya URL")
    reply_to = models.ForeignKey(
        'self',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='replies',
        verbose_name="Yanıtlanan Mesaj"
    )
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Oluşturulma Tarihi")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="Güncellenme Tarihi")
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = "Grup Mesajı"
        verbose_name_plural = "Grup Mesajları"
    
    def __str__(self):
        return f"{self.sender.username} in {self.group.name}: {self.content[:50]}..."