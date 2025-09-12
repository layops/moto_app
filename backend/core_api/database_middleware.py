"""
Database connection middleware with automatic fallback
"""
import logging
from django.conf import settings
from django.db import connection
from django.core.exceptions import ImproperlyConfigured

logger = logging.getLogger(__name__)

class DatabaseFallbackMiddleware:
    """Middleware to handle database connection failures"""
    
    def __init__(self, get_response):
        self.get_response = get_response
        self.fallback_activated = False
        
    def __call__(self, request):
        # Check database connection before processing request
        if not self.fallback_activated:
            try:
                with connection.cursor() as cursor:
                    cursor.execute("SELECT 1")
            except Exception as e:
                logger.error(f"❌ Database connection failed: {e}")
                logger.info("🔄 Activating SQLite fallback...")
                self._activate_sqlite_fallback()
        
        response = self.get_response(request)
        return response
    
    def _activate_sqlite_fallback(self):
        """Activate SQLite fallback"""
        try:
            # Update database settings to use SQLite
            settings.DATABASES['default'] = {
                'ENGINE': 'django.db.backends.sqlite3',
                'NAME': settings.BASE_DIR / 'db.sqlite3',
                'OPTIONS': {
                    'timeout': 20,
                }
            }
            
            # Close existing connections
            connection.close()
            
            # Test new connection
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
            
            self.fallback_activated = True
            logger.info("✅ SQLite fallback activated successfully")
            
        except Exception as e:
            logger.error(f"❌ Failed to activate SQLite fallback: {e}")
            self.fallback_activated = True  # Prevent infinite retry
