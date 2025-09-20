#!/usr/bin/env python
"""
Çift bucket adı sorununu düzeltmek için script
"""
import os
import sys
import django

# Django setup
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core_api.settings')
django.setup()

from django.contrib.auth import get_user_model
import logging

logger = logging.getLogger(__name__)

def fix_double_bucket_urls():
    """Çift bucket adı içeren URL'leri düzelt"""
    User = get_user_model()
    
    # Profil fotoğrafı düzeltme
    profile_fixed_count = 0
    for user in User.objects.filter(profile_picture__isnull=False):
        if user.profile_picture and 'profile_pictures/profile_pictures/' in user.profile_picture:
            old_url = user.profile_picture
            new_url = user.profile_picture.replace('profile_pictures/profile_pictures/', 'profile_pictures/')
            user.profile_picture = new_url
            user.save()
            logger.info(f"Profil fotoğrafı düzeltildi - User: {user.username}")
            logger.info(f"  Eski: {old_url}")
            logger.info(f"  Yeni: {new_url}")
            profile_fixed_count += 1
    
    # Kapak fotoğrafı düzeltme
    cover_fixed_count = 0
    for user in User.objects.filter(cover_picture__isnull=False):
        if user.cover_picture and 'cover_pictures/cover_pictures/' in user.cover_picture:
            old_url = user.cover_picture
            new_url = user.cover_picture.replace('cover_pictures/cover_pictures/', 'cover_pictures/')
            user.cover_picture = new_url
            user.save()
            logger.info(f"Kapak fotoğrafı düzeltildi - User: {user.username}")
            logger.info(f"  Eski: {old_url}")
            logger.info(f"  Yeni: {new_url}")
            cover_fixed_count += 1
    
    logger.info(f"Toplam düzeltilen profil fotoğrafı: {profile_fixed_count}")
    logger.info(f"Toplam düzeltilen kapak fotoğrafı: {cover_fixed_count}")

if __name__ == "__main__":
    print("Çift bucket adı sorununu düzeltmeye başlanıyor...")
    fix_double_bucket_urls()
    print("Düzeltme tamamlandı!")
