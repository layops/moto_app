from django.db import models
from django.conf import settings

class Group(models.Model):
    name = models.CharField(max_length=100, unique=True, verbose_name="Grup Adı")
    description = models.TextField(blank=True, verbose_name="Açıklama")
    profile_picture_url = models.URLField(blank=True, null=True, verbose_name="Profil Fotoğrafı URL")
    is_public = models.BooleanField(default=True, verbose_name="Herkese Açık Mı?")
    requires_approval = models.BooleanField(default=False, verbose_name="Onay Gerekli")

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

    @property
    def member_count(self):
        """Grup üye sayısını döndürür"""
        return self.members.count()


    def can_user_join(self, user):
        """Kullanıcının gruba katılabileceğini kontrol eder"""
        return not self.members.filter(id=user.id).exists()


class GroupJoinRequest(models.Model):
    """Grup katılım talepleri modeli"""
    STATUS_CHOICES = [
        ('pending', 'Beklemede'),
        ('approved', 'Onaylandı'),
        ('rejected', 'Reddedildi'),
    ]
    
    group = models.ForeignKey(
        Group,
        on_delete=models.CASCADE,
        related_name='join_requests',
        verbose_name="Grup"
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='group_join_requests',
        verbose_name="Kullanıcı"
    )
    message = models.TextField(blank=True, verbose_name="Mesaj")
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='pending',
        verbose_name="Durum"
    )
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Oluşturulma Tarihi")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="Güncellenme Tarihi")
    
    class Meta:
        verbose_name = "Grup Katılım Talebi"
        verbose_name_plural = "Grup Katılım Talepleri"
        unique_together = ['group', 'user']  # Bir kullanıcı aynı grup için sadece bir talep gönderebilir
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.user.username} - {self.group.name} ({self.get_status_display()})"