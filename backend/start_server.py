#!/usr/bin/env python3
"""
Startup script for production deployment
Bu script Supabase bağlantı limitlerini aşmamak için tasarlandı
"""

import os
import sys
import subprocess
import time
from pathlib import Path

def main():
    print("🚀 Starting Moto App Server...")
    
    # Django settings'i ayarla
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core_api.settings')
    
    # Static files'ı runtime'da collect et (veritabanı bağlantısı olmadan)
    print("📁 Collecting static files at runtime...")
    try:
        # Static files'ı collect et ama veritabanı bağlantısı olmadan
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
