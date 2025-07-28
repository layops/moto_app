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
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, related_name='owned_rides', on_delete=models.CASCADE, help_text="Yolculuğu oluşturan kullanıcı.")
    title = models.CharField(max_length=255, help_text="Yolculuğun veya etkinliğin başlığı.")
    description = models.TextField(blank=True, null=True, help_text="Yolculuk hakkında detaylı açıklama.")

    # Buraya yeni alanları ekliyoruz:
    route_polyline = models.TextField(
        blank=True,
        null=True,
        help_text="Harita servisinden gelen kodlanmış rota polylines'ı (encoded polyline)."
    )
    waypoints = models.JSONField( # PostgreSQL kullandığınız için JSONField kullanabiliriz.
        blank=True,
        null=True,
        help_text="Rota üzerindeki ara noktalar veya POI'lar JSON formatında.",
        default=list # Yeni kayıtlar için varsayılan boş liste
    )

    start_location = models.CharField(max_length=255, help_text="Yolculuğun başlangıç noktası.")
    end_location = models.CharField(max_length=255, help_text="Yolculuğun bitiş noktası.")
    start_time = models.DateTimeField(help_text="Yolculuğun başlangıç tarihi ve saati.")
    end_time = models.DateTimeField(blank=True, null=True, help_text="Yolculuğun tahmini bitiş tarihi ve saati (isteğe bağlı).")
    participants = models.ManyToManyField(settings.AUTH_USER_MODEL, related_name='participating_rides', blank=True, help_text="Yolculuğa katılan kullanıcılar.")
    max_participants = models.PositiveIntegerField(blank=True, null=True, help_text="Maksimum katılımcı sayısı (isteğe bağlı).")
    is_active = models.BooleanField(default=True, help_text="Yolculuğun hala aktif olup olmadığı.")
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