from django.db import models
from django.conf import settings
from django.utils import timezone
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
    requires_approval = models.BooleanField(default=False, verbose_name="Onay Gerekli")
    
    event_image = models.URLField(
        blank=True,
        null=True,
        verbose_name="Event Resmi URL"
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
    def is_expired(self):
        """Event'in süresi geçmiş mi kontrol et"""
        now = timezone.now()
        # end_time varsa onu kullan, yoksa start_time'ı kullan
        event_end = self.end_time if self.end_time else self.start_time
        return event_end < now
    
    @property
    def days_since_end(self):
        """Event bitiş tarihinden kaç gün geçmiş"""
        if self.is_expired:
            now = timezone.now()
            event_end = self.end_time if self.end_time else self.start_time
            return (now - event_end).days
        return 0
    
    @classmethod
    def get_expired_events(cls, days_after=7):
        """Süresi geçmiş event'leri getir"""
        now = timezone.now()
        cutoff_date = now - timezone.timedelta(days=days_after)
        
        return cls.objects.filter(
            models.Q(
                models.Q(end_time__isnull=False, end_time__lt=cutoff_date) |
                models.Q(end_time__isnull=True, start_time__lt=cutoff_date)
            )
        )
    
    @classmethod
    def cleanup_expired(cls, days_after=7, dry_run=False):
        """Süresi geçmiş event'leri temizle"""
        expired_events = cls.get_expired_events(days_after)
        count = expired_events.count()
        
        if dry_run:
            return count, []
        
        deleted_events = []
        for event in expired_events:
            deleted_events.append({
                'id': event.id,
                'title': event.title,
                'organizer': event.organizer.username,
                'start_time': event.start_time,
                'end_time': event.end_time
            })
            event.delete()
        
        return count, deleted_events
    
    @property
    def current_participant_count(self):
        try:
            # Organizatörü de katılımcı sayısına dahil et
            # Organizatör zaten participants içinde mi kontrol et
            if self.organizer in self.participants.all():
                return self.participants.count()
            else:
                return self.participants.count() + 1
        except Exception as e:
            print(f"current_participant_count hatası: {str(e)}")
            return 0
    
    def is_full(self):
        try:
            if self.guest_limit is None:
                return False
            return self.current_participant_count >= self.guest_limit
        except Exception as e:
            print(f"is_full hatası: {str(e)}")
            return False
    
    def get_user_request_status(self, user):
        """Kullanıcının bu etkinlik için istek durumunu döndürür"""
        try:
            if not self.requires_approval:
                return None
            
            request = EventRequest.objects.filter(event=self, user=user).first()
            if request:
                return request.status
            return None
        except Exception as e:
            print(f"get_user_request_status hatası: {str(e)}")
            return None


class EventRequest(models.Model):
    """Etkinlik katılım istekleri"""
    STATUS_CHOICES = [
        ('pending', 'Beklemede'),
        ('approved', 'Onaylandı'),
        ('rejected', 'Reddedildi'),
    ]
    
    event = models.ForeignKey(Event, on_delete=models.CASCADE, related_name='requests')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='event_requests')
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='pending')
    message = models.TextField(blank=True, null=True, verbose_name="İstek Mesajı")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ('event', 'user')
        ordering = ['-created_at']
        verbose_name = "Etkinlik Katılım İsteği"
        verbose_name_plural = "Etkinlik Katılım İstekleri"
    
    def __str__(self):
        return f"{self.user.username} - {self.event.title} ({self.status})"