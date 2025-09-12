"""
Database query optimization utilities
"""
from django.db import models
from django.db.models import Prefetch, select_related, prefetch_related
from django.core.cache import cache
from typing import List, Dict, Any
import logging

logger = logging.getLogger(__name__)

class QueryOptimizer:
    """Utility class for optimizing database queries"""
    
    @staticmethod
    def optimize_posts_queryset():
        """Optimize posts queryset with related data"""
        from posts.models import Post
        from users.models import CustomUser
        from groups.models import Group
        
        return Post.objects.select_related(
            'author',
            'group'
        ).prefetch_related(
            'likes__user',
            'comments__author',
            'comments'
        ).order_by('-created_at')
    
    @staticmethod
    def optimize_rides_queryset():
        """Optimize rides queryset with related data"""
        from rides.models import Ride
        from users.models import CustomUser
        
        return Ride.objects.select_related(
            'owner',
            'group'
        ).prefetch_related(
            'participants',
            'requests__requester'
        ).order_by('-start_time')
    
    @staticmethod
    def optimize_groups_queryset():
        """Optimize groups queryset with related data"""
        from groups.models import Group
        from users.models import CustomUser
        
        return Group.objects.select_related(
            'owner'
        ).prefetch_related(
            'members',
            'posts__author'
        ).order_by('-created_at')
    
    @staticmethod
    def optimize_users_queryset():
        """Optimize users queryset with related data"""
        from users.models import CustomUser
        
        return CustomUser.objects.prefetch_related(
            'following',
            'followers',
            'posts',
            'owned_rides'
        )

class CacheOptimizer:
    """Utility class for cache optimization"""
    
    @staticmethod
    def get_cached_posts(group_id: int = None, limit: int = 20):
        """Get cached posts with fallback to database"""
        cache_key = f"posts_{group_id}_{limit}" if group_id else f"posts_all_{limit}"
        
        cached_posts = cache.get(cache_key)
        if cached_posts:
            logger.info(f"Cache hit for posts: {cache_key}")
            return cached_posts
        
        # Fallback to database
        queryset = QueryOptimizer.optimize_posts_queryset()
        if group_id:
            queryset = queryset.filter(group_id=group_id)
        
        posts = list(queryset[:limit])
        
        # Cache for 5 minutes
        cache.set(cache_key, posts, 300)
        logger.info(f"Cache miss for posts: {cache_key}, cached {len(posts)} posts")
        
        return posts
    
    @staticmethod
    def get_cached_user_profile(user_id: int):
        """Get cached user profile with fallback to database"""
        cache_key = f"user_profile_{user_id}"
        
        cached_profile = cache.get(cache_key)
        if cached_profile:
            return cached_profile
        
        # Fallback to database
        from users.models import CustomUser
        try:
            user = CustomUser.objects.select_related().prefetch_related(
                'following',
                'followers',
                'posts',
                'owned_rides'
            ).get(id=user_id)
            
            # Cache for 10 minutes
            cache.set(cache_key, user, 600)
            return user
        except CustomUser.DoesNotExist:
            return None
    
    @staticmethod
    def invalidate_user_cache(user_id: int):
        """Invalidate all cache entries for a user"""
        patterns = [
            f"user_profile_{user_id}",
            f"user_posts_{user_id}",
            f"user_rides_{user_id}",
            f"user_groups_{user_id}",
        ]
        
        for pattern in patterns:
            cache.delete(pattern)
        
        logger.info(f"Invalidated cache for user: {user_id}")

class PaginationOptimizer:
    """Utility class for pagination optimization"""
    
    @staticmethod
    def get_optimized_page_data(queryset, page: int = 1, page_size: int = 20):
        """Get optimized paginated data"""
        start = (page - 1) * page_size
        end = start + page_size
        
        # Use slicing for better performance
        items = list(queryset[start:end])
        total_count = queryset.count()
        
        return {
            'items': items,
            'total_count': total_count,
            'page': page,
            'page_size': page_size,
            'has_next': end < total_count,
            'has_previous': page > 1,
            'total_pages': (total_count + page_size - 1) // page_size
        }
