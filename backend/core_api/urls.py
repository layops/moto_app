from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.views.generic import RedirectView
from rest_framework import permissions
from drf_yasg.views import get_schema_view
from drf_yasg import openapi
from django.http import HttpResponse

# ------------------------------
# Swagger / Redoc için
# ------------------------------
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

# ------------------------------
# Basit index view
# ------------------------------
def index(request):
    return HttpResponse("Site çalışıyor! /api/ altında API endpointlerini kullanabilirsiniz.")

# ------------------------------
# URL Patterns
# ------------------------------
urlpatterns = [
    # Ana sayfa
    path('', index, name='index'),

    # Admin paneli
    path('admin/', admin.site.urls),

    # API Root → otomatik Swagger yönlendirmesi
    path('api/', RedirectView.as_view(url='/swagger/', permanent=False)),

    # Users app
    path('api/users/', include('users.urls')),

    # Search app
    path('api/search/', include('search.urls')),

    # Diğer uygulamalar
    path('api/bikes/', include('bikes.urls')),
    path('api/rides/', include('rides.urls')),
    path('api/groups/', include('groups.urls')),
    path('api/events/', include('events.urls')),
    path('api/posts/', include('posts.urls')),
    path('api/notifications/', include('notifications.urls')),
    path('api/gamification/', include('gamification.urls')),

    # Swagger / Redoc
    path('swagger/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    path('redoc/', schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),

    # DRF login/logout
    path('api-auth/', include('rest_framework.urls', namespace='rest_framework')),
]

# DEBUG modunda medya ve statik dosyaları servis et
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
