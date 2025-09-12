"""
Rate limiting utilities for API endpoints
"""
from django.core.cache import cache
from django.http import JsonResponse
from django.utils import timezone
from functools import wraps
from typing import Dict, Any
import logging

logger = logging.getLogger(__name__)

class RateLimiter:
    """Rate limiting utility class"""
    
    @staticmethod
    def is_rate_limited(key: str, limit: int, window: int) -> bool:
        """
        Check if a request should be rate limited
        
        Args:
            key: Unique identifier for the rate limit (e.g., user_id, ip_address)
            limit: Maximum number of requests allowed
            window: Time window in seconds
            
        Returns:
            True if rate limited, False otherwise
        """
        now = timezone.now().timestamp()
        window_start = now - window
        
        # Get current requests from cache
        requests = cache.get(key, [])
        
        # Filter requests within the time window
        requests = [req_time for req_time in requests if req_time > window_start]
        
        # Check if limit exceeded
        if len(requests) >= limit:
            return True
        
        # Add current request
        requests.append(now)
        
        # Update cache
        cache.set(key, requests, window)
        
        return False
    
    @staticmethod
    def get_rate_limit_info(key: str, limit: int, window: int) -> Dict[str, Any]:
        """Get rate limit information"""
        now = timezone.now().timestamp()
        window_start = now - window
        
        requests = cache.get(key, [])
        requests = [req_time for req_time in requests if req_time > window_start]
        
        return {
            'limit': limit,
            'remaining': max(0, limit - len(requests)),
            'reset_time': window_start + window,
            'window': window
        }

def rate_limit(limit: int = 100, window: int = 3600, key_func=None):
    """
    Decorator for rate limiting API endpoints
    
    Args:
        limit: Maximum number of requests allowed
        window: Time window in seconds
        key_func: Function to generate rate limit key from request
    """
    def decorator(view_func):
        @wraps(view_func)
        def wrapper(request, *args, **kwargs):
            # Generate rate limit key
            if key_func:
                key = key_func(request)
            else:
                # Default: use user ID if authenticated, otherwise IP
                if request.user.is_authenticated:
                    key = f"rate_limit_user_{request.user.id}"
                else:
                    key = f"rate_limit_ip_{request.META.get('REMOTE_ADDR', 'unknown')}"
            
            # Check rate limit
            if RateLimiter.is_rate_limited(key, limit, window):
                logger.warning(f"Rate limit exceeded for key: {key}")
                return JsonResponse({
                    'error': 'Rate limit exceeded',
                    'message': f'Too many requests. Limit: {limit} per {window} seconds'
                }, status=429)
            
            # Add rate limit headers
            rate_info = RateLimiter.get_rate_limit_info(key, limit, window)
            response = view_func(request, *args, **kwargs)
            
            if hasattr(response, 'data'):
                response['X-RateLimit-Limit'] = limit
                response['X-RateLimit-Remaining'] = rate_info['remaining']
                response['X-RateLimit-Reset'] = rate_info['reset_time']
            
            return response
        
        return wrapper
    return decorator

# Predefined rate limiters for common use cases
def login_rate_limit(view_func):
    """Rate limiter for login attempts"""
    return rate_limit(limit=5, window=900, key_func=lambda r: f"login_{r.META.get('REMOTE_ADDR', 'unknown')}")(view_func)

def registration_rate_limit(view_func):
    """Rate limiter for registration attempts"""
    return rate_limit(limit=3, window=3600, key_func=lambda r: f"register_{r.META.get('REMOTE_ADDR', 'unknown')}")(view_func)

def api_rate_limit(view_func):
    """Rate limiter for general API endpoints"""
    return rate_limit(limit=1000, window=3600)(view_func)

def upload_rate_limit(view_func):
    """Rate limiter for file uploads"""
    return rate_limit(limit=10, window=3600)(view_func)
