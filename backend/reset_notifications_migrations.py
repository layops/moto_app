#!/usr/bin/env python
"""
Migration dosyalarını sıfırlama scripti
Bu script notifications app'indeki tüm migration dosyalarını siler
ve tek bir migration oluşturur.
"""

import os
import shutil

def reset_notifications_migrations():
    """Notifications migration dosyalarını sıfırla"""
    
    migrations_dir = "backend/notifications/migrations"
    
    # Migration dosyalarını listele (__init__.py hariç)
    migration_files = [f for f in os.listdir(migrations_dir) 
                      if f.endswith('.py') and f != '__init__.py']
    
    print(f"Silinecek migration dosyaları: {migration_files}")
    
    # Migration dosyalarını sil
    for file in migration_files:
        file_path = os.path.join(migrations_dir, file)
        os.remove(file_path)
        print(f"Silindi: {file}")
    
    print("✅ Tüm migration dosyaları silindi")
    print("Şimdi şu komutları çalıştırın:")
    print("1. python manage.py makemigrations notifications")
    print("2. python manage.py migrate notifications --fake")

if __name__ == "__main__":
    reset_notifications_migrations()
