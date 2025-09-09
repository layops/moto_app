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
    image_url = models.URLField(
        blank=True,
        null=True,
        verbose_name="Görsel URL (Supabase)"
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

    @property
    def likes_count(self):
        return self.likes.count()

    @property
    def comments_count(self):
        return self.comments.count()


class PostLike(models.Model):
    post = models.ForeignKey(
        Post,
        on_delete=models.CASCADE,
        related_name='likes',
        verbose_name="Gönderi"
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='post_likes',
        verbose_name="Kullanıcı"
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name="Oluşturulma Tarihi"
    )

    class Meta:
        verbose_name = "Gönderi Beğenisi"
        verbose_name_plural = "Gönderi Beğenileri"
        unique_together = ['post', 'user']  # Bir kullanıcı aynı postu sadece bir kez beğenebilir

    def __str__(self):
        return f"{self.user.username} liked {self.post.id}"


class PostComment(models.Model):
    post = models.ForeignKey(
        Post,
        on_delete=models.CASCADE,
        related_name='comments',
        verbose_name="Gönderi"
    )
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='post_comments',
        verbose_name="Yazar"
    )
    content = models.TextField(verbose_name="Yorum İçeriği")
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name="Oluşturulma Tarihi"
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name="Güncellenme Tarihi"
    )

    class Meta:
        verbose_name = "Gönderi Yorumu"
        verbose_name_plural = "Gönderi Yorumları"
        ordering = ['-created_at']

    def __str__(self):
        return f"Comment by {self.author.username} on post {self.post.id}"