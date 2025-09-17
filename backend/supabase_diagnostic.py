#!/usr/bin/env python3
"""
Supabase Diagnostic Script
Bu script Supabase bağlantı sorunlarını teşhis eder
"""

import os
import sys
import time
import psycopg2
from urllib.parse import urlparse

def diagnose_supabase():
    """Supabase bağlantısını teşhis et"""
    print("🔍 Supabase Diagnostic Tool")
    print("=" * 50)
    
    # 1. Environment Variables kontrolü
    print("\n1️⃣ Environment Variables:")
    DATABASE_URL = os.environ.get('DATABASE_URL')
    if DATABASE_URL:
        print(f"✅ DATABASE_URL found: {DATABASE_URL[:50]}...")
        
        # URL'yi parse et
        try:
            result = urlparse(DATABASE_URL)
            print(f"   Host: {result.hostname}")
            print(f"   Port: {result.port}")
            print(f"   Database: {result.path[1:]}")
            print(f"   User: {result.username}")
            print(f"   Password: {'*' * len(result.password) if result.password else 'None'}")
        except Exception as e:
            print(f"❌ URL parsing error: {e}")
            return False
    else:
        print("❌ DATABASE_URL not found")
        return False
    
    # 2. Network connectivity test
    print("\n2️⃣ Network Connectivity:")
    try:
        import socket
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        result = sock.connect_ex((result.hostname, result.port))
        sock.close()
        
        if result == 0:
            print(f"✅ Network connection to {result.hostname}:{result.port} successful")
        else:
            print(f"❌ Network connection to {result.hostname}:{result.port} failed")
            return False
    except Exception as e:
        print(f"❌ Network test error: {e}")
        return False
    
    # 3. PostgreSQL connection test
    print("\n3️⃣ PostgreSQL Connection:")
    for attempt in range(3):
        try:
            print(f"   Attempt {attempt + 1}/3...")
            conn = psycopg2.connect(
                host=result.hostname,
                port=result.port,
                database=result.path[1:],
                user=result.username,
                password=result.password,
                connect_timeout=10,
                sslmode='require'
            )
            
            # Connection test
            cursor = conn.cursor()
            cursor.execute("SELECT version();")
            version = cursor.fetchone()[0]
            print(f"✅ PostgreSQL connection successful")
            print(f"   Version: {version}")
            
            # Connection pool test
            cursor.execute("SELECT count(*) FROM pg_stat_activity;")
            active_connections = cursor.fetchone()[0]
            print(f"   Active connections: {active_connections}")
            
            cursor.close()
            conn.close()
            return True
            
        except psycopg2.OperationalError as e:
            print(f"❌ Connection attempt {attempt + 1} failed: {e}")
            if attempt < 2:
                print("   Waiting 5 seconds before retry...")
                time.sleep(5)
        except Exception as e:
            print(f"❌ Unexpected error: {e}")
            return False
    
    return False

def test_django_connection():
    """Django database connection test"""
    print("\n4️⃣ Django Database Connection:")
    try:
        os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core_api.settings')
        import django
        django.setup()
        
        from django.db import connection
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1;")
            result = cursor.fetchone()
            if result[0] == 1:
                print("✅ Django database connection successful")
                return True
            else:
                print("❌ Django database connection failed")
                return False
    except Exception as e:
        print(f"❌ Django connection error: {e}")
        return False

def main():
    print("🚀 Starting Supabase Diagnostic...")
    
    # Supabase teşhisi
    supabase_ok = diagnose_supabase()
    
    # Django teşhisi
    django_ok = test_django_connection()
    
    # Sonuç
    print("\n" + "=" * 50)
    print("📊 DIAGNOSTIC RESULTS:")
    print(f"Supabase Connection: {'✅ OK' if supabase_ok else '❌ FAILED'}")
    print(f"Django Connection: {'✅ OK' if django_ok else '❌ FAILED'}")
    
    if supabase_ok and django_ok:
        print("\n🎉 All tests passed! Supabase is working correctly.")
        return 0
    else:
        print("\n⚠️ Some tests failed. Check the issues above.")
        return 1

if __name__ == '__main__':
    sys.exit(main())
