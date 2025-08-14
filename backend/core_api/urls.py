from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.views.generic import RedirectView
from rest_framework import permissions
from drf_yasg.views import get_schema_view
from drf_yasg import openapi

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

urlpatterns = [
    # Kök URL'yi /api/ dizinine yönlendirme
    path('', RedirectView.as_view(url='/api/', permanent=True)),

    # Admin paneli
    path('admin/', admin.site.urls),

    # API endpointleri
    path('api/', include('users.urls')),
    path('api/', include('bikes.urls')),
    path('api/', include('rides.urls')),

    # Groups app
    path('api/groups/', include('groups.urls')),  

    # Group-related Events app
    path('api/', include('events.urls')),  # /groups/<group_pk>/events/ şeklinde URL yapısı

    # Group posts app
    path('api/', include('group_posts.urls')),  # yeni eklenen post endpointleri

    # Notifications & Gamification
    path('api/', include('notifications.urls')),
    path('api/', include('gamification.urls')),

    # Swagger / Redoc
    path('swagger/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    path('redoc/', schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),

    # DRF login/logout
    path('api/', include('rest_framework.urls', namespace='rest_framework')),
]

# DEBUG modunda medya ve statik dosyaları servis et
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
