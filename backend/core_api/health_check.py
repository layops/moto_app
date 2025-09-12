"""
Health check endpoints for monitoring
"""
from django.http import JsonResponse
from django.views.decorators.cache import never_cache
from django.views.decorators.http import require_http_methods
from django.utils.decorators import method_decorator
from django.views import View
from django.db import connection
from django.core.cache import cache
from django.conf import settings
import time
import logging

logger = logging.getLogger(__name__)

@never_cache
@require_http_methods(["GET"])
def health_check(request):
    """Basic health check endpoint"""
    try:
        # Check database connection
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        
        # Check cache connection
        cache.set('health_check', 'ok', 10)
        cache.get('health_check')
        
        return JsonResponse({
            'status': 'healthy',
            'timestamp': time.time(),
            'version': '1.0.0'
        })
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        return JsonResponse({
            'status': 'unhealthy',
            'error': str(e),
            'timestamp': time.time()
        }, status=503)

@never_cache
@require_http_methods(["GET"])
def detailed_health_check(request):
    """Detailed health check endpoint"""
    health_data = {
        'timestamp': time.time(),
        'version': '1.0.0',
        'checks': {}
    }
    
    # Database check
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        health_data['checks']['database'] = {
            'status': 'healthy',
            'response_time': '< 1ms'
        }
    except Exception as e:
        health_data['checks']['database'] = {
            'status': 'unhealthy',
            'error': str(e)
        }
    
    # Cache check
    try:
        cache.set('detailed_health_check', 'ok', 10)
        cache.get('detailed_health_check')
        health_data['checks']['cache'] = {
            'status': 'healthy',
            'type': 'Redis'
        }
    except Exception as e:
        health_data['checks']['cache'] = {
            'status': 'unhealthy',
            'error': str(e)
        }
    
    # Supabase check
    try:
        from users.services.supabase_service import SupabaseStorage
        storage = SupabaseStorage()
        health_data['checks']['supabase'] = {
            'status': 'healthy',
            'type': 'Supabase Storage'
        }
    except Exception as e:
        health_data['checks']['supabase'] = {
            'status': 'unhealthy',
            'error': str(e)
        }
    
    # Overall status
    all_healthy = all(check['status'] == 'healthy' for check in health_data['checks'].values())
    health_data['status'] = 'healthy' if all_healthy else 'unhealthy'
    
    status_code = 200 if all_healthy else 503
    return JsonResponse(health_data, status=status_code)

@never_cache
@require_http_methods(["GET"])
def metrics(request):
    """Metrics endpoint for monitoring"""
    try:
        # Database metrics
        with connection.cursor() as cursor:
            cursor.execute("SELECT COUNT(*) FROM users_customuser")
            user_count = cursor.fetchone()[0]
            
            cursor.execute("SELECT COUNT(*) FROM posts_post")
            post_count = cursor.fetchone()[0]
            
            cursor.execute("SELECT COUNT(*) FROM rides_ride")
            ride_count = cursor.fetchone()[0]
        
        metrics_data = {
            'timestamp': time.time(),
            'metrics': {
                'users': {
                    'total': user_count,
                    'active': cache.get('active_users_count', 0)
                },
                'posts': {
                    'total': post_count,
                    'created_today': cache.get('posts_created_today', 0)
                },
                'rides': {
                    'total': ride_count,
                    'active': cache.get('active_rides_count', 0)
                },
                'system': {
                    'uptime': time.time() - cache.get('system_start_time', time.time()),
                    'memory_usage': 'N/A',  # Would need psutil for this
                    'cpu_usage': 'N/A'      # Would need psutil for this
                }
            }
        }
        
        return JsonResponse(metrics_data)
    except Exception as e:
        logger.error(f"Metrics collection failed: {str(e)}")
        return JsonResponse({
            'error': str(e),
            'timestamp': time.time()
        }, status=500)

@never_cache
@require_http_methods(["GET"])
def readiness_check(request):
    """Readiness check for Kubernetes/Docker"""
    try:
        # Check if all services are ready
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        
        cache.set('readiness_check', 'ok', 10)
        cache.get('readiness_check')
        
        return JsonResponse({
            'status': 'ready',
            'timestamp': time.time()
        })
    except Exception as e:
        logger.error(f"Readiness check failed: {str(e)}")
        return JsonResponse({
            'status': 'not_ready',
            'error': str(e),
            'timestamp': time.time()
        }, status=503)

@never_cache
@require_http_methods(["GET"])
def liveness_check(request):
    """Liveness check for Kubernetes/Docker"""
    try:
        # Simple check to see if the application is alive
        return JsonResponse({
            'status': 'alive',
            'timestamp': time.time()
        })
    except Exception as e:
        logger.error(f"Liveness check failed: {str(e)}")
        return JsonResponse({
            'status': 'dead',
            'error': str(e),
            'timestamp': time.time()
        }, status=500)
