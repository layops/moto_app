#!/usr/bin/env python3
"""
FCM Test Script
Bu script FCM push notification'ları test etmek için kullanılır
"""

import os
import sys
import django
from django.conf import settings

# Django setup
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core_api.settings')
django.setup()

from django.contrib.auth import get_user_model
from notifications.models import NotificationPreferences
import requests
import json

User = get_user_model()

def test_fcm_configuration():
    """FCM konfigürasyonunu test et"""
    print("🔍 FCM Konfigürasyon Testi")
    print("=" * 50)
    
    # FCM Server Key kontrolü
    fcm_server_key = getattr(settings, 'FCM_SERVER_KEY', None)
    if fcm_server_key:
        print(f"✅ FCM Server Key: {fcm_server_key[:20]}...")
    else:
        print("❌ FCM Server Key bulunamadı")
        return False
    
    # Kullanıcı FCM token kontrolü
    try:
        user = User.objects.get(username='emre.celik.290')
        print(f"✅ Kullanıcı bulundu: {user.username}")
        
        try:
            preferences = NotificationPreferences.objects.get(user=user)
            if preferences.fcm_token:
                print(f"✅ FCM Token: {preferences.fcm_token[:50]}...")
                return True
            else:
                print("❌ FCM Token boş")
                return False
        except NotificationPreferences.DoesNotExist:
            print("❌ NotificationPreferences bulunamadı")
            return False
            
    except User.DoesNotExist:
        print("❌ Kullanıcı bulunamadı: emre.celik.290")
        return False

def send_test_notification():
    """Test bildirimi gönder"""
    print("\n🚀 Test Bildirimi Gönderiliyor")
    print("=" * 50)
    
    try:
        user = User.objects.get(username='emre.celik.290')
        preferences = NotificationPreferences.objects.get(user=user)
        
        fcm_token = preferences.fcm_token
        fcm_server_key = getattr(settings, 'FCM_SERVER_KEY', None)
        
        if not fcm_token:
            print("❌ FCM Token bulunamadı")
            return False
            
        if not fcm_server_key:
            print("❌ FCM Server Key bulunamadı")
            return False
        
        # FCM API endpoint
        url = 'https://fcm.googleapis.com/fcm/send'
        
        # Headers
        headers = {
            'Authorization': f'key={fcm_server_key}',
            'Content-Type': 'application/json',
        }
        
        # Payload
        payload = {
            'to': fcm_token,
            'notification': {
                'title': 'Test Bildirimi',
                'body': 'Bu bir test bildirimidir. FCM çalışıyor!',
                'sound': 'default',
                'badge': 1,
            },
            'data': {
                'notification_type': 'test',
                'user_id': str(user.id),
                'username': user.username,
            },
            'priority': 'high',
        }
        
        # Request gönder
        response = requests.post(url, headers=headers, data=json.dumps(payload))
        
        if response.status_code == 200:
            result = response.json()
            if result.get('success') == 1:
                print("✅ Test bildirimi başarıyla gönderildi!")
                print(f"   Message ID: {result.get('message_id')}")
                return True
            else:
                print(f"❌ FCM hatası: {result}")
                return False
        else:
            print(f"❌ HTTP hatası: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Hata: {e}")
        return False

def main():
    print("🧪 FCM Test Script")
    print("=" * 50)
    
    # Konfigürasyon testi
    config_ok = test_fcm_configuration()
    
    if config_ok:
        # Test bildirimi gönder
        send_ok = send_test_notification()
        
        if send_ok:
            print("\n🎉 FCM Test Başarılı!")
            print("Telefonunuzda bildirim geldi mi kontrol edin.")
        else:
            print("\n❌ FCM Test Başarısız!")
    else:
        print("\n❌ FCM Konfigürasyon Sorunu!")

if __name__ == '__main__':
    main()

