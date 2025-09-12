# moto_app/backend/rides/models.py

from django.db import models
from django.conf import settings
from django.contrib.auth import get_user_model
# Eğer Django 3.1+ ve PostgreSQL kullanıyorsanız JSONField için import etmelisiniz.
# Zaten kullanıyorsunuz, bu import'un ekli olması gerekiyor.
# from django.contrib.postgres.fields import JSONField

User = get_user_model()

# Create your models here.
class Ride(models.Model):
    RIDE_TYPES = [
        ('casual', 'Günlük Sürüş'),
        ('touring', 'Tur Sürüşü'),
        ('group', 'Grup Sürüşü'),
        ('track', 'Pist Sürüşü'),
        ('adventure', 'Macera Sürüşü'),
    ]
    
    PRIVACY_LEVELS = [
        ('public', 'Herkese Açık'),
        ('friends', 'Sadece Arkadaşlar'),
        ('private', 'Özel'),
    ]
    
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, related_name='owned_rides', on_delete=models.CASCADE, help_text="Yolculuğu oluşturan kullanıcı.")
    title = models.CharField(max_length=255, help_text="Yolculuğun veya etkinliğin başlığı.")
    description = models.TextField(blank=True, null=True, help_text="Yolculuk hakkında detaylı açıklama.")
    
    # Rota bilgileri
    route_polyline = models.TextField(
        blank=True,
        null=True,
        help_text="Harita servisinden gelen kodlanmış rota polylines'ı (encoded polyline)."
    )
    waypoints = models.JSONField(
        blank=True,
        null=True,
        help_text="Rota üzerindeki ara noktalar veya POI'lar JSON formatında.",
        default=list
    )
    
    # Konum bilgileri
    start_location = models.CharField(max_length=255, help_text="Yolculuğun başlangıç noktası.")
    end_location = models.CharField(max_length=255, help_text="Yolculuğun bitiş noktası.")
    start_coordinates = models.JSONField(
        blank=True,
        null=True,
        help_text="Başlangıç koordinatları [lat, lng]",
        default=list
    )
    end_coordinates = models.JSONField(
        blank=True,
        null=True,
        help_text="Bitiş koordinatları [lat, lng]",
        default=list
    )
    
    # Zaman bilgileri
    start_time = models.DateTimeField(help_text="Yolculuğun başlangıç tarihi ve saati.")
    end_time = models.DateTimeField(blank=True, null=True, help_text="Yolculuğun tahmini bitiş tarihi ve saati (isteğe bağlı).")
    completed_at = models.DateTimeField(blank=True, null=True, help_text="Yolculuğun tamamlanma tarihi.")
    
    # Katılımcı bilgileri
    participants = models.ManyToManyField(settings.AUTH_USER_MODEL, related_name='participating_rides', blank=True, help_text="Yolculuğa katılan kullanıcılar.")
    max_participants = models.PositiveIntegerField(blank=True, null=True, help_text="Maksimum katılımcı sayısı (isteğe bağlı).")
    
    # Rota özellikleri
    ride_type = models.CharField(max_length=20, choices=RIDE_TYPES, default='casual', help_text="Yolculuk türü.")
    privacy_level = models.CharField(max_length=20, choices=PRIVACY_LEVELS, default='public', help_text="Gizlilik seviyesi.")
    distance_km = models.FloatField(blank=True, null=True, help_text="Toplam mesafe (km).")
    estimated_duration_minutes = models.PositiveIntegerField(blank=True, null=True, help_text="Tahmini süre (dakika).")
    
    # Durum bilgileri
    is_active = models.BooleanField(default=True, help_text="Yolculuğun hala aktif olup olmadığı.")
    is_favorite = models.BooleanField(default=False, help_text="Favori rota mı?")
    
    # Grup bilgileri
    group = models.ForeignKey('groups.Group', on_delete=models.SET_NULL, null=True, blank=True, related_name='group_rides', help_text="Bağlı grup.")
    
    # Meta bilgiler
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-start_time']

    def __str__(self):
        return self.title


class RideRequest(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Beklemede'),
        ('approved', 'Onaylandı'),
        ('rejected', 'Reddedildi'),
        ('cancelled', 'İptal Edildi'),
    ]

    ride = models.ForeignKey(Ride, related_name='requests', on_delete=models.CASCADE)
    requester = models.ForeignKey(User, related_name='ride_requests', on_delete=models.CASCADE)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        # Bir kullanıcının aynı yolculuğa birden fazla istek gönderememesini sağlar
        unique_together = ('ride', 'requester')
        ordering = ['created_at']

    def __str__(self):
        return f"{self.requester.username} - {self.ride.title} ({self.status})"


class RouteFavorite(models.Model):
    """Kullanıcıların favori rotaları"""
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='favorite_routes')
    ride = models.ForeignKey(Ride, on_delete=models.CASCADE, related_name='favorited_by')
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['user', 'ride']
        verbose_name = "Favori Rota"
        verbose_name_plural = "Favori Rotalar"
    
    def __str__(self):
        return f"{self.user.username} - {self.ride.title}"


class LocationShare(models.Model):
    """Real-time konum paylaşımı"""
    SHARE_TYPES = [
        ('ride', 'Yolculuk Sırasında'),
        ('group', 'Grup Üyeleri'),
        ('friends', 'Arkadaşlar'),
        ('public', 'Herkese Açık'),
    ]
    
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='location_shares')
    ride = models.ForeignKey(Ride, on_delete=models.CASCADE, null=True, blank=True, related_name='location_shares')
    group = models.ForeignKey('groups.Group', on_delete=models.CASCADE, null=True, blank=True, related_name='location_shares')
    
    latitude = models.FloatField(help_text="Enlem")
    longitude = models.FloatField(help_text="Boylam")
    accuracy = models.FloatField(blank=True, null=True, help_text="Konum doğruluğu (metre)")
    speed = models.FloatField(blank=True, null=True, help_text="Hız (km/h)")
    heading = models.FloatField(blank=True, null=True, help_text="Yön (derece)")
    
    share_type = models.CharField(max_length=20, choices=SHARE_TYPES, default='ride')
    is_active = models.BooleanField(default=True, help_text="Paylaşım aktif mi?")
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = "Konum Paylaşımı"
        verbose_name_plural = "Konum Paylaşımları"
    
    def __str__(self):
        return f"{self.user.username} - {self.latitude}, {self.longitude}"


class RouteTemplate(models.Model):
    """Hazır rota şablonları"""
    TEMPLATE_CATEGORIES = [
        ('city', 'Şehir İçi'),
        ('highway', 'Otoyol'),
        ('mountain', 'Dağ'),
        ('coastal', 'Sahil'),
        ('historical', 'Tarihi'),
        ('nature', 'Doğa'),
    ]
    
    name = models.CharField(max_length=255, help_text="Şablon adı")
    description = models.TextField(blank=True, help_text="Açıklama")
    category = models.CharField(max_length=20, choices=TEMPLATE_CATEGORIES, default='city')
    
    route_polyline = models.TextField(help_text="Rota polylines")
    waypoints = models.JSONField(default=list, help_text="Ara noktalar")
    start_location = models.CharField(max_length=255, help_text="Başlangıç")
    end_location = models.CharField(max_length=255, help_text="Bitiş")
    distance_km = models.FloatField(help_text="Mesafe (km)")
    estimated_duration_minutes = models.PositiveIntegerField(help_text="Tahmini süre (dakika)")
    
    difficulty_level = models.PositiveIntegerField(default=1, help_text="Zorluk seviyesi (1-5)")
    is_public = models.BooleanField(default=True, help_text="Herkese açık mı?")
    
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='created_templates')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = "Rota Şablonu"
        verbose_name_plural = "Rota Şablonları"
    
    def __str__(self):
        return self.name