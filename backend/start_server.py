#!/usr/bin/env python3
"""
Startup script for production deployment
Bu script Supabase bağlantı sorunlarını çözmek için offline mode kullanır
"""

import os
import sys
import subprocess
import time
from pathlib import Path

def main():
    print("🚀 Starting Moto App Server in OFFLINE MODE...")
    
    # Django settings'i ayarla
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core_api.settings')
    
    # Offline mode'u aktif et
    os.environ['OFFLINE_MODE'] = 'true'
    print("⚠️ OFFLINE MODE activated - using SQLite instead of Supabase")
    
    # Static files'ı runtime'da collect et
    print("📁 Collecting static files at runtime...")
    try:
        # Static files'ı collect et
        result = subprocess.run([
            sys.executable, 'manage.py', 'collectstatic', '--noinput', '--clear'
        ], capture_output=True, text=True, timeout=30)
        
        if result.returncode == 0:
            print("✅ Static files collected successfully")
        else:
            print(f"⚠️ Static files collection warning: {result.stderr}")
    except subprocess.TimeoutExpired:
        print("⚠️ Static files collection timed out - continuing anyway")
    except Exception as e:
        print(f"⚠️ Static files collection failed: {e} - continuing anyway")
    
    # SQLite migration'ları çalıştır
    print("🗄️ Running SQLite migrations...")
    try:
        result = subprocess.run([
            sys.executable, 'manage.py', 'migrate', '--noinput'
        ], capture_output=True, text=True, timeout=60)
        
        if result.returncode == 0:
            print("✅ SQLite migrations completed successfully")
        else:
            print(f"⚠️ Migration warning: {result.stderr}")
    except subprocess.TimeoutExpired:
        print("⚠️ Migrations timed out - continuing anyway")
    except Exception as e:
        print(f"⚠️ Migrations failed: {e} - continuing anyway")
    
    # Superuser oluştur
    print("👤 Creating superuser...")
    try:
        result = subprocess.run([
            sys.executable, 'manage.py', 'shell', '-c', '''
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username="superuser").exists():
    User.objects.create_superuser("superuser", "superuser@spiride.com", "326598")
    print("Superuser created successfully")
else:
    print("Superuser already exists")
'''
        ], capture_output=True, text=True, timeout=30)
        
        if result.returncode == 0:
            print("✅ Superuser creation completed")
        else:
            print(f"⚠️ Superuser creation warning: {result.stderr}")
    except Exception as e:
        print(f"⚠️ Superuser creation failed: {e} - continuing anyway")
    
    # Uvicorn server'ı başlat
    print("🌐 Starting Uvicorn server...")
    port = os.environ.get('PORT', '8000')
    
    try:
        # Uvicorn'u başlat
        subprocess.run([
            sys.executable, '-m', 'uvicorn', 
            'core_api.asgi:application',
            '--host', '0.0.0.0',
            '--port', port,
            '--workers', '1',
            '--log-level', 'info'
        ])
    except KeyboardInterrupt:
        print("\n🛑 Server stopped by user")
    except Exception as e:
        print(f"❌ Server error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
