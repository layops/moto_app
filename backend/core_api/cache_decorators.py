"""
Caching decorators for API views
"""
import hashlib
import json
from functools import wraps
from django.core.cache import cache
from django.conf import settings
from django.http import JsonResponse
from typing import Any, Callable, Optional

def cache_api_response(timeout: Optional[int] = None, key_prefix: str = ""):
    """
    Decorator to cache API responses
    
    Args:
        timeout: Cache timeout in seconds (uses default if None)
        key_prefix: Prefix for cache key
    """
    def decorator(view_func: Callable) -> Callable:
        @wraps(view_func)
        def wrapper(request, *args, **kwargs):
            # Generate cache key based on request
            cache_key = _generate_cache_key(request, key_prefix, *args, **kwargs)
            
            # Try to get from cache
            cached_response = cache.get(cache_key)
            if cached_response is not None:
                return JsonResponse(cached_response)
            
            # Execute the view function
            response = view_func(request, *args, **kwargs)
            
            # Cache the response if it's successful
            if hasattr(response, 'status_code') and response.status_code == 200:
                if hasattr(response, 'data'):
                    cache_timeout = timeout or getattr(settings, 'CACHE_TIMEOUTS', {}).get(key_prefix, 300)
                    cache.set(cache_key, response.data, cache_timeout)
            
            return response
        
        return wrapper
    return decorator

def cache_user_data(timeout: int = 600):
    """
    Decorator to cache user-specific data
    """
    def decorator(view_func: Callable) -> Callable:
        @wraps(view_func)
        def wrapper(request, *args, **kwargs):
            if not request.user.is_authenticated:
                return view_func(request, *args, **kwargs)
            
            user_id = request.user.id
            cache_key = f"user_{user_id}_{view_func.__name__}_{_generate_request_hash(request)}"
            
            # Try to get from cache
            cached_data = cache.get(cache_key)
            if cached_data is not None:
                return JsonResponse(cached_data)
            
            # Execute the view function
            response = view_func(request, *args, **kwargs)
            
            # Cache the response if it's successful
            if hasattr(response, 'status_code') and response.status_code == 200:
                if hasattr(response, 'data'):
                    cache.set(cache_key, response.data, timeout)
            
            return response
        
        return wrapper
    return decorator

def invalidate_cache_pattern(pattern: str):
    """
    Decorator to invalidate cache entries matching a pattern
    """
    def decorator(view_func: Callable) -> Callable:
        @wraps(view_func)
        def wrapper(request, *args, **kwargs):
            response = view_func(request, *args, **kwargs)
            
            # Invalidate cache after successful operation
            if hasattr(response, 'status_code') and response.status_code in [200, 201, 204]:
                _invalidate_cache_by_pattern(pattern)
            
            return response
        
        return wrapper
    return decorator

def _generate_cache_key(request, prefix: str, *args, **kwargs) -> str:
    """Generate a unique cache key for the request"""
    # Get request parameters
    params = {
        'method': request.method,
        'path': request.path,
        'query_params': dict(request.GET),
        'user_id': request.user.id if request.user.is_authenticated else None,
        'args': args,
        'kwargs': kwargs,
    }
    
    # Create hash from parameters
    params_str = json.dumps(params, sort_keys=True, default=str)
    params_hash = hashlib.md5(params_str.encode()).hexdigest()
    
    return f"{prefix}_{params_hash}" if prefix else params_hash

def _generate_request_hash(request) -> str:
    """Generate hash from request parameters"""
    params = {
        'path': request.path,
        'query_params': dict(request.GET),
        'method': request.method,
    }
    params_str = json.dumps(params, sort_keys=True, default=str)
    return hashlib.md5(params_str.encode()).hexdigest()

def _invalidate_cache_by_pattern(pattern: str):
    """Invalidate cache entries matching the pattern"""
    try:
        # This is a simplified version - in production you might want to use Redis SCAN
        # For now, we'll use a more targeted approach
        cache.delete_many([pattern])
    except Exception:
        # If cache invalidation fails, log but don't break the request
        import logging
        logger = logging.getLogger(__name__)
        logger.warning(f"Failed to invalidate cache pattern: {pattern}")

class CacheManager:
    """Utility class for cache management"""
    
    @staticmethod
    def clear_user_cache(user_id: int):
        """Clear all cache entries for a specific user"""
        patterns = [
            f"user_{user_id}_*",
            f"user_profile_{user_id}",
            f"user_posts_{user_id}_*",
            f"notifications_{user_id}",
        ]
        
        for pattern in patterns:
            _invalidate_cache_by_pattern(pattern)
    
    @staticmethod
    def clear_group_cache(group_id: int):
        """Clear all cache entries for a specific group"""
        patterns = [
            f"group_posts_{group_id}_*",
            f"group_{group_id}_*",
        ]
        
        for pattern in patterns:
            _invalidate_cache_by_pattern(pattern)
    
    @staticmethod
    def clear_global_cache():
        """Clear all cache entries"""
        cache.clear()
