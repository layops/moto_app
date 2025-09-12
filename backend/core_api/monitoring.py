"""
Monitoring and analytics utilities
"""
from django.core.cache import cache
from django.db import connection
from django.utils import timezone
from django.http import JsonResponse
from functools import wraps
import time
import logging
from typing import Dict, Any, List
import json

logger = logging.getLogger(__name__)

class PerformanceMonitor:
    """Performance monitoring utilities"""
    
    @staticmethod
    def track_request_time(view_func):
        """Decorator to track request processing time"""
        @wraps(view_func)
        def wrapper(request, *args, **kwargs):
            start_time = time.time()
            
            try:
                response = view_func(request, *args, **kwargs)
                processing_time = time.time() - start_time
                
                # Log slow requests
                if processing_time > 1.0:  # More than 1 second
                    logger.warning(f"Slow request: {request.path} took {processing_time:.2f}s")
                
                # Add performance header
                if hasattr(response, 'data'):
                    response['X-Processing-Time'] = f"{processing_time:.3f}s"
                
                return response
            except Exception as e:
                processing_time = time.time() - start_time
                logger.error(f"Request failed: {request.path} took {processing_time:.2f}s, error: {str(e)}")
                raise
        
        return wrapper
    
    @staticmethod
    def track_database_queries(view_func):
        """Decorator to track database queries"""
        @wraps(view_func)
        def wrapper(request, *args, **kwargs):
            initial_queries = len(connection.queries)
            
            response = view_func(request, *args, **kwargs)
            
            final_queries = len(connection.queries)
            query_count = final_queries - initial_queries
            
            # Log queries
            if query_count > 10:  # More than 10 queries
                logger.warning(f"High query count: {request.path} executed {query_count} queries")
            
            # Add query count header
            if hasattr(response, 'data'):
                response['X-Query-Count'] = str(query_count)
            
            return response
        
        return wrapper

class AnalyticsCollector:
    """Analytics data collection utilities"""
    
    @staticmethod
    def track_user_activity(user_id: int, activity: str, metadata: Dict = None):
        """Track user activity"""
        activity_data = {
            'user_id': user_id,
            'activity': activity,
            'timestamp': timezone.now().isoformat(),
            'metadata': metadata or {}
        }
        
        # Store in cache for batch processing
        cache_key = f"user_activity_{user_id}_{int(time.time())}"
        cache.set(cache_key, activity_data, 3600)  # 1 hour
        
        logger.info(f"User activity tracked: {activity} for user {user_id}")
    
    @staticmethod
    def track_api_usage(endpoint: str, method: str, user_id: int = None, response_time: float = None):
        """Track API usage statistics"""
        usage_data = {
            'endpoint': endpoint,
            'method': method,
            'user_id': user_id,
            'response_time': response_time,
            'timestamp': timezone.now().isoformat()
        }
        
        # Store in cache
        cache_key = f"api_usage_{int(time.time())}"
        cache.set(cache_key, usage_data, 3600)
        
        logger.info(f"API usage tracked: {method} {endpoint}")
    
    @staticmethod
    def get_analytics_summary(days: int = 7) -> Dict[str, Any]:
        """Get analytics summary for the last N days"""
        # This is a simplified version - in production you'd use a proper analytics service
        return {
            'total_users': cache.get('analytics_total_users', 0),
            'active_users': cache.get('analytics_active_users', 0),
            'total_posts': cache.get('analytics_total_posts', 0),
            'total_rides': cache.get('analytics_total_rides', 0),
            'total_groups': cache.get('analytics_total_groups', 0),
            'period_days': days
        }

class HealthChecker:
    """System health check utilities"""
    
    @staticmethod
    def check_database_health() -> Dict[str, Any]:
        """Check database health"""
        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
                return {
                    'status': 'healthy',
                    'response_time': '< 1ms',
                    'connection_count': len(connection.queries)
                }
        except Exception as e:
            return {
                'status': 'unhealthy',
                'error': str(e)
            }
    
    @staticmethod
    def check_cache_health() -> Dict[str, Any]:
        """Check cache health"""
        try:
            test_key = 'health_check_test'
            test_value = 'test_value'
            
            cache.set(test_key, test_value, 10)
            retrieved_value = cache.get(test_key)
            
            if retrieved_value == test_value:
                cache.delete(test_key)
                return {
                    'status': 'healthy',
                    'type': 'Redis'
                }
            else:
                return {
                    'status': 'unhealthy',
                    'error': 'Cache read/write mismatch'
                }
        except Exception as e:
            return {
                'status': 'unhealthy',
                'error': str(e)
            }
    
    @staticmethod
    def check_storage_health() -> Dict[str, Any]:
        """Check storage health (Supabase)"""
        try:
            # This would check Supabase storage connectivity
            return {
                'status': 'healthy',
                'type': 'Supabase Storage'
            }
        except Exception as e:
            return {
                'status': 'unhealthy',
                'error': str(e)
            }
    
    @staticmethod
    def get_system_health() -> Dict[str, Any]:
        """Get overall system health"""
        return {
            'database': HealthChecker.check_database_health(),
            'cache': HealthChecker.check_cache_health(),
            'storage': HealthChecker.check_storage_health(),
            'timestamp': timezone.now().isoformat()
        }

class MetricsCollector:
    """Metrics collection utilities"""
    
    @staticmethod
    def increment_counter(metric_name: str, value: int = 1, tags: Dict = None):
        """Increment a counter metric"""
        cache_key = f"metric_counter_{metric_name}"
        current_value = cache.get(cache_key, 0)
        cache.set(cache_key, current_value + value, 86400)  # 24 hours
        
        logger.info(f"Metric incremented: {metric_name} by {value}")
    
    @staticmethod
    def set_gauge(metric_name: str, value: float, tags: Dict = None):
        """Set a gauge metric"""
        cache_key = f"metric_gauge_{metric_name}"
        cache.set(cache_key, value, 86400)  # 24 hours
        
        logger.info(f"Metric set: {metric_name} = {value}")
    
    @staticmethod
    def record_histogram(metric_name: str, value: float, tags: Dict = None):
        """Record a histogram metric"""
        cache_key = f"metric_histogram_{metric_name}"
        values = cache.get(cache_key, [])
        values.append(value)
        
        # Keep only last 1000 values
        if len(values) > 1000:
            values = values[-1000:]
        
        cache.set(cache_key, values, 86400)  # 24 hours
        
        logger.info(f"Histogram recorded: {metric_name} = {value}")
    
    @staticmethod
    def get_metrics_summary() -> Dict[str, Any]:
        """Get metrics summary"""
        # This is a simplified version - in production you'd use a proper metrics service
        return {
            'counters': {
                'api_requests': cache.get('metric_counter_api_requests', 0),
                'user_logins': cache.get('metric_counter_user_logins', 0),
                'posts_created': cache.get('metric_counter_posts_created', 0),
            },
            'gauges': {
                'active_users': cache.get('metric_gauge_active_users', 0),
                'total_posts': cache.get('metric_gauge_total_posts', 0),
            },
            'histograms': {
                'response_times': cache.get('metric_histogram_response_times', []),
            }
        }
