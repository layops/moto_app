"""
Database connection retry mekanizması
Supabase bağlantı sorunlarını çözmek için
"""
import time
import logging
from django.db import connection
from django.db.utils import OperationalError
from functools import wraps

logger = logging.getLogger(__name__)

def retry_database_connection(max_retries=3, delay=1, backoff=2):
    """
    Database bağlantı hatalarında retry mekanizması
    """
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            retries = 0
            current_delay = delay
            
            while retries < max_retries:
                try:
                    # Bağlantıyı test et
                    connection.ensure_connection()
                    return func(*args, **kwargs)
                    
                except OperationalError as e:
                    retries += 1
                    error_msg = str(e)
                    
                    logger.warning(f"Database bağlantı hatası (deneme {retries}/{max_retries}): {error_msg}")
                    
                    if retries >= max_retries:
                        logger.error(f"Database bağlantısı {max_retries} deneme sonrası başarısız")
                        raise e
                    
                    # Bağlantıyı kapat ve yeniden dene
                    try:
                        connection.close()
                    except:
                        pass
                    
                    logger.info(f"{current_delay} saniye bekleyip tekrar deneniyor...")
                    time.sleep(current_delay)
                    current_delay *= backoff
                    
                except Exception as e:
                    # Diğer hatalar için retry yapma
                    logger.error(f"Database olmayan hata: {str(e)}")
                    raise e
            
            return func(*args, **kwargs)
        return wrapper
    return decorator

def test_database_connection():
    """
    Database bağlantısını test et
    """
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            result = cursor.fetchone()
            logger.info("✅ Database bağlantısı başarılı")
            return True
    except Exception as e:
        logger.error(f"❌ Database bağlantı hatası: {str(e)}")
        return False

def get_database_status():
    """
    Database durumunu kontrol et
    """
    try:
        with connection.cursor() as cursor:
            # Bağlantı bilgilerini al
            cursor.execute("SELECT version()")
            version = cursor.fetchone()[0]
            
            cursor.execute("SELECT current_database()")
            db_name = cursor.fetchone()[0]
            
            cursor.execute("SELECT current_user")
            user = cursor.fetchone()[0]
            
            cursor.execute("SELECT inet_server_addr(), inet_server_port()")
            server_info = cursor.fetchone()
            
            return {
                'connected': True,
                'version': version,
                'database': db_name,
                'user': user,
                'server_addr': server_info[0],
                'server_port': server_info[1]
            }
    except Exception as e:
        return {
            'connected': False,
            'error': str(e)
        }
