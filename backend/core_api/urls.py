from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.views.generic import RedirectView
from rest_framework import permissions
from drf_yasg.views import get_schema_view
from drf_yasg import openapi
from django.http import HttpResponse, FileResponse
import os
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
    TokenBlacklistView,
)
from .views import api_root, get_csrf_token
from .health_check import health_check, detailed_health_check, metrics, readiness_check, liveness_check, debug_database, create_test_data, test_database_connection, database_status, jwt_debug, cache_test

# Swagger / Redoc için
schema_view = get_schema_view(
    openapi.Info(
        title="Motosiklet Bilgi Platformu API",
        default_version='v1',
        description="Motosikletlerin ve Yolculukların Yönetimi için API Dokümantasyonu",
        terms_of_service="https://www.google.com/policies/terms/",
        contact=openapi.Contact(email="contact@yourdomain.com"),
        license=openapi.License(name="BSD License"),
    ),
    public=True,
    permission_classes=[permissions.AllowAny],
)

# Basit index view
def index(request):
    return HttpResponse("Site çalışıyor! /api/ altında API endpointlerini kullanabilirsiniz.")

# Favicon views
def favicon(request):
    """Ana favicon - 32x32 boyutunda"""
    favicon_path = os.path.join(os.path.dirname(__file__), 'static', 'favicon.ico')
    if os.path.exists(favicon_path):
        return FileResponse(open(favicon_path, 'rb'), content_type='image/x-icon')
    else:
        return HttpResponse(status=404)

def favicon_192(request):
    """Büyük favicon - 192x192 boyutunda"""
    favicon_path = os.path.join(os.path.dirname(__file__), 'static', 'favicon-192.png')
    if os.path.exists(favicon_path):
        return FileResponse(open(favicon_path, 'rb'), content_type='image/png')
    else:
        return HttpResponse(status=404)

def favicon_512(request):
    """En büyük favicon - 512x512 boyutunda"""
    favicon_path = os.path.join(os.path.dirname(__file__), 'static', 'favicon-512.png')
    if os.path.exists(favicon_path):
        return FileResponse(open(favicon_path, 'rb'), content_type='image/png')
    else:
        return HttpResponse(status=404)

def assetlinks(request):
    """Android App Links için assetlinks.json dosyasını serve et"""
    assetlinks_path = os.path.join(os.path.dirname(__file__), '.well-known', 'assetlinks.json')
    if os.path.exists(assetlinks_path):
        return FileResponse(open(assetlinks_path, 'rb'), content_type='application/json')
    else:
        return HttpResponse(status=404)

# URL Patterns
urlpatterns = [
    # Ana sayfa
    path('', index, name='index'),
    
    # Favicons - farklı boyutlarda
    path('favicon.ico', favicon, name='favicon'),
    path('favicon-192.png', favicon_192, name='favicon-192'),
    path('favicon-512.png', favicon_512, name='favicon-512'),
    
    # Android App Links
    path('.well-known/assetlinks.json', assetlinks, name='assetlinks'),
    
    # API Root
    path('api/', api_root, name='api-root'),
    
    # CSRF Token
    path('api/csrf-token/', get_csrf_token, name='csrf-token'),

    # Admin paneli
    path('admin/', admin.site.urls),

    # JWT Token endpoints
    path('api/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/token/blacklist/', TokenBlacklistView.as_view(), name='token_blacklist'),

    # Users app
    path('api/users/', include('users.urls')),

    # Diğer uygulamalar - DÜZELTME: api/ ön ekini kaldırın
    path('api/bikes/', include('bikes.urls')),
    path('api/rides/', include('rides.urls')),
    path('api/groups/', include('groups.urls')),
    path('api/events/', include('events.urls')),
    path('api/posts/', include('posts.urls')),  # DÜZELTME: Bu satırı olduğu gibi bırakın
    path('api/notifications/', include('notifications.urls')),
    path('api/gamification/', include('gamification.urls')),
    path('api/chat/', include('chat.urls')),
    path('api/search/', include('search.urls')),

    # Swagger / Redoc
    path('swagger/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    path('redoc/', schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),

    # DRF login/logout
    path('api-auth/', include('rest_framework.urls', namespace='rest_framework')),
    
    # Health check endpoints
    path('health/', health_check, name='health-check'),
    path('health/detailed/', detailed_health_check, name='detailed-health-check'),
    path('health/cache-test/', cache_test, name='cache-test'),
    path('metrics/', metrics, name='metrics'),
    path('ready/', readiness_check, name='readiness-check'),
    path('live/', liveness_check, name='liveness-check'),
    
    # Debug endpoints
    path('debug/database/', debug_database, name='debug-database'),
    path('debug/test-connection/', test_database_connection, name='test-database-connection'),
    path('debug/database-status/', database_status, name='database-status'),
    path('debug/jwt/', jwt_debug, name='jwt-debug'),
    path('debug/create-test-data/', create_test_data, name='create-test-data'),
]

# Media serving kaldırıldı - Supabase Storage kullanılıyor
# if settings.DEBUG:
#     urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)