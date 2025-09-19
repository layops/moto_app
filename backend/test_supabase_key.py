#!/usr/bin/env python
"""
Supabase SERVICE_KEY Test Script
"""
import os
import sys

# Environment variable'ı set et
os.environ['SUPABASE_SERVICE_KEY'] = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vc2lxa3l5cmliemx2ZHZlZGV0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NjY0MzQ3NSwiZXhwIjoyMDcyMjE5NDc1fQ.oxEaRtYZF74vTIttVCaBhmeNaEyUAEdQHVbSWYOPTUA'
os.environ['SUPABASE_URL'] = 'https://mosiqkyyribzlvdvedet.supabase.co'

try:
    from supabase import create_client, Client
    
    print("=== SUPABASE SERVICE_KEY TEST ===")
    print(f"SUPABASE_URL: {os.environ.get('SUPABASE_URL')}")
    print(f"SUPABASE_SERVICE_KEY: {'VAR' if os.environ.get('SUPABASE_SERVICE_KEY') else 'YOK'}")
    
    # Supabase client oluştur
    client = create_client(
        os.environ.get('SUPABASE_URL'),
        os.environ.get('SUPABASE_SERVICE_KEY')
    )
    
    print("✅ Supabase client başarıyla oluşturuldu")
    
    # Bucket'ları kontrol et
    try:
        buckets = client.storage.list_buckets()
        bucket_names = [bucket.name for bucket in buckets]
        print(f"📁 Mevcut bucket'lar: {bucket_names}")
        
        if 'events_pictures' in bucket_names:
            print("✅ events_pictures bucket mevcut")
        else:
            print("❌ events_pictures bucket bulunamadı")
            
    except Exception as e:
        print(f"❌ Bucket listesi alınamadı: {e}")
        
except Exception as e:
    print(f"❌ Supabase client oluşturulamadı: {e}")
