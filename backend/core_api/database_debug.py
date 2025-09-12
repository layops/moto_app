"""
Database debug utilities
"""
from django.db import connection
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.apps import apps

User = get_user_model()

class DatabaseDebugger:
    """Database debug utilities"""
    
    @staticmethod
    def check_database_status():
        """Check database status and tables"""
        print("🔍 Database Debug Information")
        print("=" * 50)
        
        # Database vendor
        print(f"Database Vendor: {connection.vendor}")
        print(f"Database Name: {connection.settings_dict.get('NAME', 'Unknown')}")
        
        # Check if database file exists (for SQLite)
        if connection.vendor == 'sqlite':
            db_path = connection.settings_dict.get('NAME')
            import os
            if os.path.exists(db_path):
                print(f"✅ SQLite database file exists: {db_path}")
                file_size = os.path.getsize(db_path)
                print(f"📁 Database file size: {file_size} bytes")
            else:
                print(f"❌ SQLite database file not found: {db_path}")
        
        # List all tables
        with connection.cursor() as cursor:
            if connection.vendor == 'sqlite':
                cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
            else:
                cursor.execute("SELECT tablename FROM pg_tables WHERE schemaname = 'public';")
            
            tables = cursor.fetchall()
            print(f"\n📋 Tables in database ({len(tables)}):")
            for table in tables:
                table_name = table[0]
                print(f"  - {table_name}")
                
                # Count records in each table
                try:
                    cursor.execute(f"SELECT COUNT(*) FROM {table_name};")
                    count = cursor.fetchone()[0]
                    print(f"    Records: {count}")
                except Exception as e:
                    print(f"    Error counting records: {e}")
        
        print("\n" + "=" * 50)
    
    @staticmethod
    def check_user_data():
        """Check user data specifically"""
        print("👥 User Data Check")
        print("=" * 30)
        
        try:
            user_count = User.objects.count()
            print(f"Total users: {user_count}")
            
            if user_count > 0:
                print("\nFirst 5 users:")
                users = User.objects.all()[:5]
                for user in users:
                    print(f"  - ID: {user.id}, Username: {user.username}, Email: {user.email}")
            else:
                print("❌ No users found in database")
                
        except Exception as e:
            print(f"❌ Error checking user data: {e}")
        
        print("\n" + "=" * 30)
    
    @staticmethod
    def check_migration_status():
        """Check migration status"""
        print("🔄 Migration Status Check")
        print("=" * 35)
        
        try:
            with connection.cursor() as cursor:
                if connection.vendor == 'sqlite':
                    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='django_migrations';")
                else:
                    cursor.execute("SELECT tablename FROM pg_tables WHERE tablename = 'django_migrations';")
                
                if cursor.fetchone():
                    print("✅ django_migrations table exists")
                    
                    # Get applied migrations
                    cursor.execute("SELECT app, name FROM django_migrations ORDER BY applied;")
                    migrations = cursor.fetchall()
                    
                    print(f"\n📋 Applied migrations ({len(migrations)}):")
                    for migration in migrations:
                        print(f"  - {migration[0]}.{migration[1]}")
                else:
                    print("❌ django_migrations table not found")
                    
        except Exception as e:
            print(f"❌ Error checking migration status: {e}")
        
        print("\n" + "=" * 35)
    
    @staticmethod
    def create_test_data():
        """Create test data if database is empty"""
        print("🧪 Creating Test Data")
        print("=" * 25)
        
        try:
            # Check if superuser exists
            if not User.objects.filter(username='admin').exists():
                User.objects.create_superuser(
                    username='admin',
                    email='admin@test.com',
                    password='admin123'
                )
                print("✅ Superuser 'admin' created")
            else:
                print("ℹ️ Superuser 'admin' already exists")
            
            # Check if test users exist
            test_users = [
                {'username': 'testuser1', 'email': 'test1@test.com', 'first_name': 'Test', 'last_name': 'User1'},
                {'username': 'testuser2', 'email': 'test2@test.com', 'first_name': 'Test', 'last_name': 'User2'},
            ]
            
            for user_data in test_users:
                if not User.objects.filter(username=user_data['username']).exists():
                    User.objects.create_user(
                        username=user_data['username'],
                        email=user_data['email'],
                        first_name=user_data['first_name'],
                        last_name=user_data['last_name'],
                        password='test123'
                    )
                    print(f"✅ Test user '{user_data['username']}' created")
                else:
                    print(f"ℹ️ Test user '{user_data['username']}' already exists")
            
            print(f"\n📊 Total users now: {User.objects.count()}")
            
        except Exception as e:
            print(f"❌ Error creating test data: {e}")
        
        print("\n" + "=" * 25)

def debug_database():
    """Main debug function"""
    DatabaseDebugger.check_database_status()
    DatabaseDebugger.check_migration_status()
    DatabaseDebugger.check_user_data()
    DatabaseDebugger.create_test_data()
