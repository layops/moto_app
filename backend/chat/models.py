from django.db import models
from django.conf import settings

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