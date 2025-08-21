# core_api/urls.py

from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from rest_framework.routers import DefaultRouter
from drf_yasg.views import get_schema_view
from drf_yasg import openapi
from rest_framework import permissions
from django.http import HttpResponse

schema_view = get_schema_view(
    openapi.Info(
        title="Motosiklet Bilgi Platformu API",
        default_version='v1',
        description="Motosikletlerin ve Yolculukların Yönetimi için API Dokümantasyonu",
        contact=openapi.Contact(email="contact@yourdomain.com"),
        license=openapi.License(name="BSD License"),
    ),
    public=True,
    permission_classes=[permissions.AllowAny],
)

def index(request):
    return HttpResponse("Site çalışıyor! /api/ altında API endpointlerini kullanabilirsiniz.")

urlpatterns = [
    path('', index, name='index'),

    # Admin
    path('admin/', admin.site.urls),

    # API Root
    path('api/', include([
        path('users/', include('users.urls')),
        path('bikes/', include('bikes.urls')),
        path('rides/', include('rides.urls')),
        path('groups/', include('groups.urls')),
        path('events/', include('events.urls')),
        path('posts/', include('posts.urls')),
        path('notifications/', include('notifications.urls')),
        path('gamification/', include('gamification.urls')),
    ])),

    # Swagger / Redoc
    path('swagger/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    path('redoc/', schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),

    # DRF login/logout
    path('api-auth/', include('rest_framework.urls', namespace='rest_framework')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
