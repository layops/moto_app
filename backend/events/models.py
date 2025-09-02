from django.db import models
from django.conf import settings
from groups.models import Group

class Event(models.Model):
    group = models.ForeignKey(
        Group,
        on_delete=models.CASCADE,
        related_name='events',
        verbose_name="Grup",
        null=True,
        blank=True
    )
    organizer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='organized_events',
        verbose_name="Organizatör"
    )
    title = models.CharField(max_length=200, verbose_name="Etkinlik Başlığı")
    description = models.TextField(blank=True, verbose_name="Açıklama")
    location = models.CharField(max_length=255, verbose_name="Yer", blank=True)
    start_time = models.DateTimeField(verbose_name="Başlangıç Zamanı")
    end_time = models.DateTimeField(verbose_name="Bitiş Zamanı", null=True, blank=True)
    participants = models.ManyToManyField(
        settings.AUTH_USER_MODEL,
        related_name='participated_events',
        blank=True,
        verbose_name="Katılımcılar"
    )
    is_public = models.BooleanField(default=True, verbose_name="Herkese Açık")
    guest_limit = models.PositiveIntegerField(null=True, blank=True, verbose_name="Katılımcı Sınırı")
    
    # Supabase ile uyumlu URL alanı
    cover_image = models.URLField(
        blank=True,
        null=True,
        verbose_name="Kapak Resmi URL"
    )

    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Oluşturulma Tarihi")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="Güncellenme Tarihi")

    class Meta:
        verbose_name = "Etkinlik"
        verbose_name_plural = "Etkinlikler"
        ordering = ['start_time']

    def __str__(self):
        grp = self.group.name if self.group else "Personal"
        return f"Event: {self.title} in {grp} by {self.organizer.username}"
    
    @property
    def current_participant_count(self):
        return self.participants.count()
    
    def is_full(self):
        if self.guest_limit is None:
            return False
        return self.current_participant_count >= self.guest_limit