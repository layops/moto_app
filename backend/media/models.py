# moto_app/backend/media/models.py

from django.db import models
from django.conf import settings # AUTH_USER_MODEL için
from groups.models import Group # Group modelini import edin

class Media(models.Model):
    group = models.ForeignKey(Group, on_delete=models.CASCADE, related_name='group_media', blank=True, null=True)
    file_url = models.URLField(blank=True, null=True) # Supabase URL'i
    description = models.TextField(blank=True, null=True)
    uploaded_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='media')
    uploaded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name_plural = "Media"
        ordering = ['-uploaded_at']


    def __str__(self):
        return f"{self.group.name} - {self.file.name}"