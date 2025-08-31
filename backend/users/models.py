# users/models.py
from django.contrib.auth.models import AbstractUser
from django.db import models


class CustomUser(AbstractUser):
    phone_number = models.CharField(max_length=15, blank=True, null=True, unique=True)
    address = models.CharField(max_length=255, blank=True, null=True)
    profile_picture = models.URLField(blank=True, null=True, verbose_name="Profil Resmi URL")

    # Takip ilişkisi (self-referential)
    following = models.ManyToManyField(
        'self',
        symmetrical=False,
        related_name='followers',
        blank=True
    )

    # Yeni profil alanları
    bio = models.TextField(blank=True, null=True, verbose_name="Hakkımda")
    motorcycle_model = models.CharField(max_length=100, blank=True, null=True, verbose_name="Motosiklet Modeli")
    location = models.CharField(max_length=100, blank=True, null=True, verbose_name="Konum")
    website = models.URLField(blank=True, null=True, verbose_name="Web Sitesi")

    def __str__(self):
        return self.username