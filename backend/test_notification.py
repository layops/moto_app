#!/usr/bin/env python3
"""
Test bildirimi gönderme scripti
Uygulama kapalıyken bildirim testi için kullanılır
"""

import requests
import json
import sys

# API Base URL
BASE_URL = "https://spiride.onrender.com/api"

def test_notification():
    """Test bildirimi gönder"""
    
    # Test kullanıcısı - kendi kullanıcı adınızı buraya yazın
    test_username = "emre.celik.290"  # Buraya kendi kullanıcı adınızı yazın
    
    print("🧪 Test Bildirimi Gönderme")
    print(f"📱 Hedef kullanıcı: {test_username}")
    print(f"🌐 API URL: {BASE_URL}")
    
    # Test bildirimi verisi
    test_data = {
        "recipient_username": test_username,
        "message": "🚀 Uygulama kapalıyken test bildirimi! Bu mesaj FCM ile gönderildi.",
        "notification_type": "other",
        "send_push": True  # FCM push notification gönder
    }
    
    try:
        # GET request ile basit test
        print("\n1️⃣ GET request ile basit test...")
        response = requests.get(f"{BASE_URL}/notifications/test/")
        
        if response.status_code == 200:
            print("✅ GET test başarılı!")
            print(f"📄 Response: {response.json()}")
        else:
            print(f"❌ GET test başarısız: {response.status_code}")
            print(f"📄 Response: {response.text}")
    
    except Exception as e:
        print(f"❌ GET test hatası: {e}")
    
    print("\n" + "="*50)
    
    try:
        # POST request ile detaylı test
        print("\n2️⃣ POST request ile detaylı test...")
        headers = {
            "Content-Type": "application/json",
        }
        
        response = requests.post(
            f"{BASE_URL}/notifications/test/",
            headers=headers,
            data=json.dumps(test_data)
        )
        
        if response.status_code == 200:
            print("✅ POST test başarılı!")
            print(f"📄 Response: {response.json()}")
            print("\n🎯 Şimdi uygulamayı kapatın ve bildirimi bekleyin!")
            print("📱 Bildirim 30 saniye içinde gelmelidir.")
        else:
            print(f"❌ POST test başarısız: {response.status_code}")
            print(f"📄 Response: {response.text}")
    
    except Exception as e:
        print(f"❌ POST test hatası: {e}")

if __name__ == "__main__":
    test_notification()
