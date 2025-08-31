# moto_app/backend/posts/models.py

from django.db import models
from django.conf import settings
from groups.models import Group  # Group modelini import etmeyi unutmayın

class Post(models.Model):
    group = models.ForeignKey(
        Group,
        on_delete=models.CASCADE,
        related_name='posts',
        verbose_name="Grup",
        null=True,   # Grup zorunlu değil
        blank=True   # Admin panelde boş bırakılabilir
    )
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='posts',
        verbose_name="Yazar"
    )
    content = models.TextField(verbose_name="Gönderi İçeriği")
    image = models.ImageField(
        upload_to='posts/',
        null=True,
        blank=True,
        verbose_name="Görsel"
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name="Oluşturulma Tarihi"
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name="Güncellenme Tarihi"
    )

    class Meta:
        verbose_name = "Gönderi"
        verbose_name_plural = "Gönderiler"
        ordering = ['-created_at']  # En yeni gönderi en üstte

    def __str__(self):
        group_name = self.group.name if self.group else "No Group"
        return f"Post by {self.author.username} in {group_name} - {self.content[:50]}..."
