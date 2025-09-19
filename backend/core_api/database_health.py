"""
Database health check endpoint
"""
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from django.db import connection
from django.conf import settings
import time
import logging

logger = logging.getLogger(__name__)

@api_view(['GET'])
@permission_classes([AllowAny])
def database_health_check(request):
    """
    Database bağlantı durumunu kontrol et
    """
    try:
        start_time = time.time()
        
        # Basit bir sorgu çalıştır
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1 as test")
            result = cursor.fetchone()
            
            # Database bilgilerini al
            cursor.execute("SELECT version()")
            version = cursor.fetchone()[0]
            
            cursor.execute("SELECT current_database()")
            db_name = cursor.fetchone()[0]
            
            cursor.execute("SELECT current_user")
            user = cursor.fetchone()[0]
            
        end_time = time.time()
        response_time = end_time - start_time
        
        return Response({
            'status': 'healthy',
            'database': {
                'connected': True,
                'response_time': round(response_time, 3),
                'version': version,
                'name': db_name,
                'user': user,
                'host': getattr(settings, 'DATABASE_URL', '').split('@')[1].split('/')[0] if '@' in getattr(settings, 'DATABASE_URL', '') else 'unknown'
            },
            'timestamp': time.time()
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        logger.error(f"Database health check failed: {str(e)}")
        return Response({
            'status': 'unhealthy',
            'database': {
                'connected': False,
                'error': str(e),
                'error_type': type(e).__name__
            },
            'timestamp': time.time()
        }, status=status.HTTP_503_SERVICE_UNAVAILABLE)

@api_view(['GET'])
@permission_classes([AllowAny])
def database_status(request):
    """
    Detaylı database durumu
    """
    try:
        with connection.cursor() as cursor:
            # Bağlantı bilgileri
            cursor.execute("SELECT inet_server_addr(), inet_server_port()")
            server_info = cursor.fetchone()
            
            # Aktif bağlantı sayısı
            cursor.execute("""
                SELECT count(*) 
                FROM pg_stat_activity 
                WHERE state = 'active'
            """)
            active_connections = cursor.fetchone()[0]
            
            # Database boyutu
            cursor.execute("""
                SELECT pg_size_pretty(pg_database_size(current_database()))
            """)
            db_size = cursor.fetchone()[0]
            
            # Son aktivite zamanı
            cursor.execute("""
                SELECT max(backend_start) 
                FROM pg_stat_activity 
                WHERE state = 'active'
            """)
            last_activity = cursor.fetchone()[0]
            
        return Response({
            'status': 'healthy',
            'database': {
                'server_addr': server_info[0],
                'server_port': server_info[1],
                'active_connections': active_connections,
                'database_size': db_size,
                'last_activity': last_activity.isoformat() if last_activity else None
            },
            'timestamp': time.time()
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        logger.error(f"Database status check failed: {str(e)}")
        return Response({
            'status': 'unhealthy',
            'error': str(e),
            'timestamp': time.time()
        }, status=status.HTTP_503_SERVICE_UNAVAILABLE)
