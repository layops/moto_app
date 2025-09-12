"""
Management command to fix database connection issues
"""
from django.core.management.base import BaseCommand
from django.db import connection
from django.conf import settings
import os

class Command(BaseCommand):
    help = 'Fix database connection issues'

    def add_arguments(self, parser):
        parser.add_argument(
            '--force-sqlite',
            action='store_true',
            help='Force SQLite usage',
        )
        parser.add_argument(
            '--force-postgresql',
            action='store_true',
            help='Force PostgreSQL usage',
        )

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('🔧 Database Connection Fix Tool'))
        self.stdout.write("=" * 50)
        
        # Show current database info
        self.stdout.write(f"Current Database Vendor: {connection.vendor}")
        self.stdout.write(f"Current Database Name: {connection.settings_dict.get('NAME', 'Unknown')}")
        self.stdout.write(f"Current Database Engine: {connection.settings_dict.get('ENGINE', 'Unknown')}")
        
        # Test connection
        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
                result = cursor.fetchone()
                if result[0] == 1:
                    self.stdout.write(self.style.SUCCESS("✅ Database connection successful"))
                else:
                    self.stdout.write(self.style.ERROR("❌ Database connection failed"))
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"❌ Database connection error: {e}"))
        
        # Show environment variables
        self.stdout.write("\n📋 Environment Variables:")
        self.stdout.write(f"DATABASE_URL: {'SET' if os.environ.get('DATABASE_URL') else 'NOT_SET'}")
        self.stdout.write(f"DEBUG: {settings.DEBUG}")
        
        # Show recommendations
        self.stdout.write("\n💡 Recommendations:")
        if connection.vendor == 'postgresql':
            self.stdout.write("• Currently using PostgreSQL")
            self.stdout.write("• Check DATABASE_URL format and credentials")
            self.stdout.write("• Ensure Supabase connection is working")
        else:
            self.stdout.write("• Currently using SQLite (unexpected)")
            self.stdout.write("• Check DATABASE_URL environment variable")
            self.stdout.write("• Ensure Supabase credentials are correct")
        
        # Check database file (for SQLite)
        if connection.vendor == 'sqlite':
            db_path = connection.settings_dict.get('NAME')
            if os.path.exists(db_path):
                file_size = os.path.getsize(db_path)
                self.stdout.write(f"\n📁 SQLite Database File:")
                self.stdout.write(f"Path: {db_path}")
                self.stdout.write(f"Size: {file_size} bytes")
                if file_size == 0:
                    self.stdout.write(self.style.WARNING("⚠️ Database file is empty!"))
            else:
                self.stdout.write(self.style.ERROR(f"❌ SQLite database file not found: {db_path}"))
        
        self.stdout.write("\n" + "=" * 50)
