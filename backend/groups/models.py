from django.db import models
from django.conf import settings

class Group(models.Model):
    name = models.CharField(max_length=100, unique=True, verbose_name="Grup Adı")
    description = models.TextField(blank=True, verbose_name="Açıklama")
    is_public = models.BooleanField(default=True, verbose_name="Herkese Açık Mı?")

    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='owned_groups',
        verbose_name="Grup Sahibi"
    )
    members = models.ManyToManyField(
        settings.AUTH_USER_MODEL,
        related_name='member_of_groups',
        blank=True,
        verbose_name="Üyeler"
    )
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Oluşturulma Tarihi")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="Güncellenme Tarihi")

    class Meta:
        verbose_name = "Grup"
        verbose_name_plural = "Gruplar"
        ordering = ['name']

    def __str__(self):
        return self.name
