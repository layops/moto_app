"""
Database connection utilities with retry mechanism
"""
import time
import logging
from django.db import connection
from django.core.exceptions import ImproperlyConfigured

logger = logging.getLogger(__name__)

class DatabaseConnectionManager:
    """Database connection manager with retry mechanism"""
    
    @staticmethod
    def test_connection(max_retries=3, delay=5):
        """Test database connection with retry mechanism"""
        for attempt in range(max_retries):
            try:
                with connection.cursor() as cursor:
                    cursor.execute("SELECT 1")
                logger.info("✅ Database connection successful")
                return True
            except Exception as e:
                logger.warning(f"❌ Database connection attempt {attempt + 1} failed: {e}")
                if attempt < max_retries - 1:
                    logger.info(f"🔄 Retrying in {delay} seconds...")
                    time.sleep(delay)
                else:
                    logger.error("❌ All database connection attempts failed")
                    return False
        
        return False
    
    @staticmethod
    def get_connection_info():
        """Get database connection information"""
        try:
            db_config = connection.settings_dict
            return {
                'engine': db_config.get('ENGINE'),
                'name': db_config.get('NAME'),
                'host': db_config.get('HOST'),
                'port': db_config.get('PORT'),
                'user': db_config.get('USER'),
            }
        except Exception as e:
            logger.error(f"Error getting connection info: {e}")
            return None
    
    @staticmethod
    def check_database_health():
        """Check database health status"""
        try:
            with connection.cursor() as cursor:
                # Check if we can execute a simple query
                cursor.execute("SELECT 1")
                
                # Check database version
                cursor.execute("SELECT version()")
                version = cursor.fetchone()[0]
                
                # Check connection count (PostgreSQL specific)
                if 'postgresql' in connection.settings_dict.get('ENGINE', ''):
                    cursor.execute("SELECT count(*) FROM pg_stat_activity")
                    connection_count = cursor.fetchone()[0]
                else:
                    connection_count = "N/A"
                
                return {
                    'status': 'healthy',
                    'version': version,
                    'connection_count': connection_count,
                    'connection_info': DatabaseConnectionManager.get_connection_info()
                }
        except Exception as e:
            return {
                'status': 'unhealthy',
                'error': str(e),
                'connection_info': DatabaseConnectionManager.get_connection_info()
            }

def ensure_database_connection():
    """Ensure database connection is available"""
    if not DatabaseConnectionManager.test_connection():
        logger.error("❌ Database connection failed, application may not work properly")
        return False
    return True
