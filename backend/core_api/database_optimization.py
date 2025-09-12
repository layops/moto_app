"""
Database optimization utilities and migrations
"""
from django.db import models
from django.db.models import Index
from django.core.management.base import BaseCommand

class DatabaseOptimizer:
    """Database optimization utilities"""
    
    @staticmethod
    def get_recommended_indexes():
        """Get recommended database indexes for better performance"""
        return {
            'users_customuser': [
                Index(fields=['username'], name='idx_user_username'),
                Index(fields=['email'], name='idx_user_email'),
                Index(fields=['phone_number'], name='idx_user_phone'),
                Index(fields=['created_at'], name='idx_user_created'),
            ],
            'posts_post': [
                Index(fields=['author'], name='idx_post_author'),
                Index(fields=['group'], name='idx_post_group'),
                Index(fields=['created_at'], name='idx_post_created'),
                Index(fields=['author', 'created_at'], name='idx_post_author_created'),
                Index(fields=['group', 'created_at'], name='idx_post_group_created'),
            ],
            'rides_ride': [
                Index(fields=['owner'], name='idx_ride_owner'),
                Index(fields=['start_time'], name='idx_ride_start_time'),
                Index(fields=['is_active'], name='idx_ride_active'),
                Index(fields=['ride_type'], name='idx_ride_type'),
                Index(fields=['start_location'], name='idx_ride_start_location'),
                Index(fields=['owner', 'start_time'], name='idx_ride_owner_start'),
            ],
            'groups_group': [
                Index(fields=['owner'], name='idx_group_owner'),
                Index(fields=['is_public'], name='idx_group_public'),
                Index(fields=['created_at'], name='idx_group_created'),
            ],
            'chat_privatemessage': [
                Index(fields=['sender'], name='idx_msg_sender'),
                Index(fields=['receiver'], name='idx_msg_receiver'),
                Index(fields=['timestamp'], name='idx_msg_timestamp'),
                Index(fields=['sender', 'receiver'], name='idx_msg_sender_receiver'),
                Index(fields=['is_read'], name='idx_msg_read'),
            ],
            'notifications_notification': [
                Index(fields=['recipient'], name='idx_notif_recipient'),
                Index(fields=['is_read'], name='idx_notif_read'),
                Index(fields=['timestamp'], name='idx_notif_timestamp'),
                Index(fields=['notification_type'], name='idx_notif_type'),
                Index(fields=['recipient', 'is_read'], name='idx_notif_recipient_read'),
            ],
        }
    
    @staticmethod
    def get_query_optimization_tips():
        """Get query optimization tips"""
        return {
            'select_related': [
                'Post.author',
                'Post.group',
                'Ride.owner',
                'Ride.group',
                'Group.owner',
                'PrivateMessage.sender',
                'PrivateMessage.receiver',
            ],
            'prefetch_related': [
                'Post.likes',
                'Post.comments',
                'Ride.participants',
                'Ride.requests',
                'Group.members',
                'Group.posts',
                'User.following',
                'User.followers',
            ],
            'only_fields': [
                'Post: id, content, created_at, author__username',
                'Ride: id, title, start_time, owner__username',
                'User: id, username, profile_picture',
            ],
            'defer_fields': [
                'Post: image, description',
                'User: password, last_login',
                'Ride: route_polyline, waypoints',
            ]
        }

class DatabaseHealthCheck:
    """Database health check utilities"""
    
    @staticmethod
    def check_slow_queries():
        """Check for slow queries (PostgreSQL specific)"""
        from django.db import connection
        
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT query, mean_time, calls, total_time
                FROM pg_stat_statements
                WHERE mean_time > 1000  -- queries taking more than 1 second
                ORDER BY mean_time DESC
                LIMIT 10;
            """)
            return cursor.fetchall()
    
    @staticmethod
    def check_missing_indexes():
        """Check for missing indexes"""
        from django.db import connection
        
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT schemaname, tablename, attname, n_distinct, correlation
                FROM pg_stats
                WHERE schemaname = 'public'
                AND n_distinct > 100
                AND correlation < 0.1
                ORDER BY n_distinct DESC;
            """)
            return cursor.fetchall()
    
    @staticmethod
    def get_table_sizes():
        """Get table sizes"""
        from django.db import connection
        
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT 
                    schemaname,
                    tablename,
                    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
                FROM pg_tables
                WHERE schemaname = 'public'
                ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
            """)
            return cursor.fetchall()

class CacheOptimization:
    """Cache optimization utilities"""
    
    @staticmethod
    def get_cache_keys():
        """Get all cache keys"""
        from django.core.cache import cache
        
        # This is a simplified version - in production you'd use Redis SCAN
        return [
            'user_profile_*',
            'posts_*',
            'groups_*',
            'rides_*',
            'notifications_*',
        ]
    
    @staticmethod
    def clear_expired_cache():
        """Clear expired cache entries"""
        from django.core.cache import cache
        
        # Clear cache patterns
        patterns = CacheOptimization.get_cache_keys()
        for pattern in patterns:
            try:
                cache.delete_many([pattern])
            except Exception as e:
                print(f"Error clearing cache pattern {pattern}: {e}")
    
    @staticmethod
    def optimize_cache_settings():
        """Optimize cache settings"""
        return {
            'user_profile': 600,  # 10 minutes
            'posts_list': 300,     # 5 minutes
            'groups_list': 600,    # 10 minutes
            'rides_list': 300,     # 5 minutes
            'notifications': 60,   # 1 minute
            'search_results': 180, # 3 minutes
        }
