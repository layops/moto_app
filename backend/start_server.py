#!/usr/bin/env python3
"""
Startup script for production deployment with Supabase
Bu script Supabase bağlantı sorunlarını çözmek için optimize edilmiştir
"""

import os
import sys
import subprocess
import time
from pathlib import Path

def test_supabase_connection():
    """Supabase bağlantısını test et"""
    try:
        import psycopg2
        from urllib.parse import urlparse
        
        DATABASE_URL = os.environ.get('DATABASE_URL')
        if not DATABASE_URL:
            return False, "No DATABASE_URL found"
        
        result = urlparse(DATABASE_URL)
        conn = psycopg2.connect(
            host=result.hostname,
            port=result.port,
            database=result.path[1:],
            user=result.username,
            password=result.password,
            connect_timeout=5,
            sslmode='require'
        )
        conn.close()
        return True, "Connection successful"
    except Exception as e:
        return False, str(e)

def main():
    print("🚀 Starting Moto App Server with Supabase...")
    
    # Django settings'i ayarla
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core_api.settings')
    
    # Supabase bağlantısını test et
    print("🔍 Testing Supabase connection...")
    success, message = test_supabase_connection()
    if success:
        print(f"✅ Supabase connection test: {message}")
    else:
        print(f"❌ Supabase connection test failed: {message}")
        print("🔄 Retrying in 10 seconds...")
        time.sleep(10)
        
        # Tekrar test et
        success, message = test_supabase_connection()
        if success:
            print(f"✅ Supabase connection test (retry): {message}")
        else:
            print(f"❌ Supabase connection test (retry) failed: {message}")
            print("⚠️ Continuing anyway - connection will be retried during operations")
    
    # Static files'ı runtime'da collect et
    print("📁 Collecting static files at runtime...")
    try:
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
    
    # Supabase migration'ları çalıştır (retry ile)
    print("🗄️ Running Supabase migrations...")
    for attempt in range(3):
        try:
            print(f"Migration attempt {attempt + 1}/3...")
            result = subprocess.run([
                sys.executable, 'manage.py', 'migrate', '--noinput'
            ], capture_output=True, text=True, timeout=60)
            
            if result.returncode == 0:
                print("✅ Supabase migrations completed successfully")
                break
            else:
                print(f"⚠️ Migration attempt {attempt + 1} warning: {result.stderr}")
                if attempt < 2:
                    print("⏳ Waiting 10 seconds before retry...")
                    time.sleep(10)
        except subprocess.TimeoutExpired:
            print(f"⚠️ Migration attempt {attempt + 1} timed out")
            if attempt < 2:
                print("⏳ Waiting 10 seconds before retry...")
                time.sleep(10)
        except Exception as e:
            print(f"⚠️ Migration attempt {attempt + 1} failed: {e}")
            if attempt < 2:
                print("⏳ Waiting 10 seconds before retry...")
                time.sleep(10)
    
    # Superuser oluşturma kaldırıldı - gerekli değil
    print("✅ Skipping superuser creation - not needed")
    
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
