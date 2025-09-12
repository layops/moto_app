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
from django.contrib.auth import get_user_model
import time
import logging
import os

User = get_user_model()

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
        from .database_utils import DatabaseConnectionManager
        db_health = DatabaseConnectionManager.check_database_health()
        health_data['checks']['database'] = db_health
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

@never_cache
@require_http_methods(["GET"])
def debug_database(request):
    """Debug database status and data"""
    try:
        debug_info = {
            'timestamp': time.time(),
            'database': {
                'vendor': connection.vendor,
                'name': connection.settings_dict.get('NAME', 'Unknown'),
                'tables': [],
                'user_count': 0,
                'migration_status': 'unknown',
                'app_data': {}
            }
        }
        
        # Check database file (for SQLite)
        if connection.vendor == 'sqlite':
            import os
            db_path = connection.settings_dict.get('NAME')
            debug_info['database']['file_exists'] = os.path.exists(db_path)
            if os.path.exists(db_path):
                debug_info['database']['file_size'] = os.path.getsize(db_path)
        
        # List tables
        with connection.cursor() as cursor:
            if connection.vendor == 'sqlite':
                cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
            else:
                cursor.execute("SELECT tablename FROM pg_tables WHERE schemaname = 'public';")
            
            tables = cursor.fetchall()
            for table in tables:
                table_name = table[0]
                try:
                    cursor.execute(f"SELECT COUNT(*) FROM {table_name};")
                    count = cursor.fetchone()[0]
                    debug_info['database']['tables'].append({
                        'name': table_name,
                        'record_count': count
                    })
                except Exception as e:
                    debug_info['database']['tables'].append({
                        'name': table_name,
                        'error': str(e)
                    })
        
        # Check user count
        try:
            debug_info['database']['user_count'] = User.objects.count()
        except Exception as e:
            debug_info['database']['user_count_error'] = str(e)
        
        # Check migration status
        try:
            with connection.cursor() as cursor:
                if connection.vendor == 'sqlite':
                    cursor.execute("SELECT COUNT(*) FROM django_migrations;")
                else:
                    cursor.execute("SELECT COUNT(*) FROM django_migrations;")
                migration_count = cursor.fetchone()[0]
                debug_info['database']['migration_status'] = f"{migration_count} migrations applied"
        except Exception as e:
            debug_info['database']['migration_status'] = f"Error: {str(e)}"
        
        # Check app-specific data
        try:
            from posts.models import Post
            from groups.models import Group
            from events.models import Event
            from rides.models import Ride
            
            debug_info['database']['app_data'] = {
                'posts': Post.objects.count(),
                'groups': Group.objects.count(),
                'events': Event.objects.count(),
                'rides': Ride.objects.count(),
            }
            
            # Get recent data samples
            if Post.objects.exists():
                recent_post = Post.objects.first()
                debug_info['database']['app_data']['recent_post'] = {
                    'id': recent_post.id,
                    'title': recent_post.title,
                    'author': recent_post.author.username if recent_post.author else 'No author',
                    'created_at': recent_post.created_at.isoformat()
                }
            
            if Group.objects.exists():
                recent_group = Group.objects.first()
                debug_info['database']['app_data']['recent_group'] = {
                    'id': recent_group.id,
                    'name': recent_group.name,
                    'description': recent_group.description[:100] + '...' if len(recent_group.description) > 100 else recent_group.description,
                    'created_at': recent_group.created_at.isoformat()
                }
                
        except Exception as e:
            debug_info['database']['app_data_error'] = str(e)
        
        return JsonResponse(debug_info)
        
    except Exception as e:
        logger.error(f"Database debug failed: {str(e)}")
        return JsonResponse({
            'error': str(e),
            'timestamp': time.time()
        }, status=500)

@never_cache
@require_http_methods(["GET"])
def test_database_connection(request):
    """Test database connection and show current database info"""
    try:
        db_info = {
            'timestamp': time.time(),
            'connection_test': 'success',
            'database_info': {
                'vendor': connection.vendor,
                'name': connection.settings_dict.get('NAME', 'Unknown'),
                'host': connection.settings_dict.get('HOST', 'N/A'),
                'port': connection.settings_dict.get('PORT', 'N/A'),
                'user': connection.settings_dict.get('USER', 'N/A'),
                'engine': connection.settings_dict.get('ENGINE', 'Unknown'),
            },
            'environment': {
                'USE_SQLITE_FALLBACK': os.environ.get('USE_SQLITE_FALLBACK', 'false'),
                'DATABASE_URL': 'SET' if os.environ.get('DATABASE_URL') else 'NOT_SET',
                'DEBUG': settings.DEBUG,
            },
            'connection_details': {
                'can_connect': False,
                'error': None,
                'tables_count': 0,
                'migrations_count': 0
            }
        }
        
        # Test actual connection
        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
                result = cursor.fetchone()
                db_info['connection_details']['can_connect'] = result[0] == 1
                
                # Count tables
                if connection.vendor == 'sqlite':
                    cursor.execute("SELECT COUNT(*) FROM sqlite_master WHERE type='table';")
                else:
                    cursor.execute("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';")
                db_info['connection_details']['tables_count'] = cursor.fetchone()[0]
                
                # Count migrations
                try:
                    cursor.execute("SELECT COUNT(*) FROM django_migrations;")
                    db_info['connection_details']['migrations_count'] = cursor.fetchone()[0]
                except:
                    db_info['connection_details']['migrations_count'] = 0
                    
        except Exception as e:
            db_info['connection_details']['can_connect'] = False
            db_info['connection_details']['error'] = str(e)
            db_info['connection_test'] = 'failed'
        
        # Check if we're using the right database
        if connection.vendor == 'sqlite':
            import os
            db_path = connection.settings_dict.get('NAME')
            if os.path.exists(db_path):
                db_info['database_info']['file_exists'] = True
                db_info['database_info']['file_size'] = os.path.getsize(db_path)
                db_info['database_info']['file_path'] = str(db_path)
            else:
                db_info['database_info']['file_exists'] = False
                db_info['database_info']['file_path'] = str(db_path)
        
        return JsonResponse(db_info)
        
    except Exception as e:
        logger.error(f"Database connection test failed: {str(e)}")
        return JsonResponse({
            'connection_test': 'failed',
            'error': str(e),
            'timestamp': time.time()
        }, status=500)

@never_cache
@require_http_methods(["GET"])
def database_status(request):
    """Get comprehensive database status"""
    try:
        status = {
            'timestamp': time.time(),
            'database': {
                'vendor': connection.vendor,
                'name': connection.settings_dict.get('NAME', 'Unknown'),
                'engine': connection.settings_dict.get('ENGINE', 'Unknown'),
                'host': connection.settings_dict.get('HOST', 'N/A'),
                'port': connection.settings_dict.get('PORT', 'N/A'),
                'user': connection.settings_dict.get('USER', 'N/A'),
            },
            'connection': {
                'can_connect': False,
                'error': None,
                'test_query': None
            },
            'tables': {
                'count': 0,
                'list': []
            },
            'migrations': {
                'count': 0,
                'status': 'unknown'
            },
            'environment': {
                'USE_SQLITE_FALLBACK': os.environ.get('USE_SQLITE_FALLBACK', 'false'),
                'DATABASE_URL': 'SET' if os.environ.get('DATABASE_URL') else 'NOT_SET',
                'DEBUG': settings.DEBUG,
            }
        }
        
        # Test connection
        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1 as test")
                result = cursor.fetchone()
                status['connection']['can_connect'] = True
                status['connection']['test_query'] = f"SELECT 1 = {result[0]}"
                
                # Get tables
                if connection.vendor == 'sqlite':
                    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;")
                else:
                    cursor.execute("SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;")
                
                tables = cursor.fetchall()
                status['tables']['count'] = len(tables)
                status['tables']['list'] = [table[0] for table in tables]
                
                # Get migrations
                try:
                    cursor.execute("SELECT COUNT(*) FROM django_migrations;")
                    migration_count = cursor.fetchone()[0]
                    status['migrations']['count'] = migration_count
                    status['migrations']['status'] = f"{migration_count} migrations applied"
                except Exception as e:
                    status['migrations']['status'] = f"Error: {str(e)}"
                    
        except Exception as e:
            status['connection']['can_connect'] = False
            status['connection']['error'] = str(e)
        
        # SQLite specific info
        if connection.vendor == 'sqlite':
            import os
            db_path = connection.settings_dict.get('NAME')
            status['database']['file_path'] = str(db_path)
            status['database']['file_exists'] = os.path.exists(db_path)
            if os.path.exists(db_path):
                status['database']['file_size'] = os.path.getsize(db_path)
        
        return JsonResponse(status)
        
    except Exception as e:
        logger.error(f"Database status check failed: {str(e)}")
        return JsonResponse({
            'error': str(e),
            'timestamp': time.time()
        }, status=500)

@never_cache
@require_http_methods(["POST"])
def create_test_data(request):
    """Create test data for debugging"""
    try:
        created_users = []
        
        # Create superuser if not exists
        if not User.objects.filter(username='admin').exists():
            User.objects.create_superuser(
                username='admin',
                email='admin@test.com',
                password='admin123'
            )
            created_users.append('admin (superuser)')
        
        # Create test users
        test_users = [
            {'username': 'testuser1', 'email': 'test1@test.com', 'first_name': 'Test', 'last_name': 'User1'},
            {'username': 'testuser2', 'email': 'test2@test.com', 'first_name': 'Test', 'last_name': 'User2'},
        ]
        
        for user_data in test_users:
            if not User.objects.filter(username=user_data['username']).exists():
                User.objects.create_user(
                    username=user_data['username'],
                    email=user_data['email'],
                    first_name=user_data['first_name'],
                    last_name=user_data['last_name'],
                    password='test123'
                )
                created_users.append(user_data['username'])
        
        return JsonResponse({
            'success': True,
            'message': f'Created {len(created_users)} users',
            'created_users': created_users,
            'total_users': User.objects.count(),
            'timestamp': time.time()
        })
        
    except Exception as e:
        logger.error(f"Test data creation failed: {str(e)}")
        return JsonResponse({
            'success': False,
            'error': str(e),
            'timestamp': time.time()
        }, status=500)
