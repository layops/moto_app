from django.db import models
from django.conf import settings

class Group(models.Model):
    JOIN_TYPE_CHOICES = [
        ('public', 'Herkese Açık'),
        ('private', 'Özel'),
        ('invite_only', 'Sadece Davet'),
    ]
    
    name = models.CharField(max_length=100, unique=True, verbose_name="Grup Adı")
    description = models.TextField(blank=True, verbose_name="Açıklama")
    join_type = models.CharField(
        max_length=20, 
        choices=JOIN_TYPE_CHOICES, 
        default='public',
        verbose_name="Katılım Türü"
    )
    profile_picture_url = models.URLField(blank=True, null=True, verbose_name="Profil Fotoğrafı URL")
    max_members = models.PositiveIntegerField(default=100, verbose_name="Maksimum Üye Sayısı")

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
    moderators = models.ManyToManyField(
        settings.AUTH_USER_MODEL,
        related_name='moderated_groups',
        blank=True,
        verbose_name="Moderatörler"
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
    def is_public(self):
        return self.join_type == 'public'

    @property
    def member_count(self):
        return self.members.count()

    def can_user_join(self, user):
        """Kullanıcının gruba katılıp katılamayacağını kontrol eder"""
        if user in self.members.all():
            return False, "Zaten grubun üyesisiniz"
        
        if self.member_count >= self.max_members:
            return False, "Grup dolu"
        
        if self.join_type == 'public':
            return True, "Katılabilirsiniz"
        elif self.join_type == 'private':
            return False, "Bu grup özel, katılım talebi göndermeniz gerekiyor"
        elif self.join_type == 'invite_only':
            return False, "Bu grup sadece davet ile katılım sağlar"
        
        return False, "Bilinmeyen katılım türü"


class GroupJoinRequest(models.Model):
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
    message = models.TextField(blank=True, verbose_name="Katılım Mesajı")
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='pending',
        verbose_name="Durum"
    )
    requested_at = models.DateTimeField(auto_now_add=True, verbose_name="Talep Tarihi")
    responded_at = models.DateTimeField(null=True, blank=True, verbose_name="Yanıt Tarihi")
    responded_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='responded_join_requests',
        verbose_name="Yanıtlayan"
    )

    class Meta:
        verbose_name = "Grup Katılım Talebi"
        verbose_name_plural = "Grup Katılım Talepleri"
        unique_together = ['group', 'user']
        ordering = ['-requested_at']

    def __str__(self):
        return f"{self.user.username} - {self.group.name} ({self.status})"


class GroupMessage(models.Model):
    group = models.ForeignKey(
        Group,
        on_delete=models.CASCADE,
        related_name='messages',
        verbose_name="Grup"
    )
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='group_messages',
        verbose_name="Gönderen"
    )
    content = models.TextField(verbose_name="Mesaj İçeriği")
    message_type = models.CharField(
        max_length=20,
        choices=[
            ('text', 'Metin'),
            ('image', 'Resim'),
            ('file', 'Dosya'),
            ('system', 'Sistem'),
        ],
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
    is_edited = models.BooleanField(default=False, verbose_name="Düzenlendi Mi?")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Gönderim Tarihi")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="Güncellenme Tarihi")

    class Meta:
        verbose_name = "Grup Mesajı"
        verbose_name_plural = "Grup Mesajları"
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.sender.username} - {self.group.name}: {self.content[:50]}"
