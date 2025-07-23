# users/models.py

from django.contrib.auth.models import AbstractUser
from django.db import models

class CustomUser(AbstractUser):
    # Django'nun varsayılan kullanıcı modeline eklemek istediğiniz alanları buraya ekleyin.
    phone_number = models.CharField(max_length=15, blank=True, null=True, unique=True)
    address = models.CharField(max_length=255, blank=True, null=True)
    profile_picture = models.ImageField(upload_to='profile_pictures/', blank=True, null=True)

    def __str__(self):
        return self.username