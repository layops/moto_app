from django.contrib import admin
from django.urls import path, include
from django.conf import settings  # settings.DEBUG için
from django.conf.urls.static import static  # statik ve medya dosyaları için
from django.views.generic import RedirectView  # Anasayfa yönlendirmesi için

# drf-yasg (Swagger/OpenAPI) importları
from rest_framework import permissions
from drf_yasg.views import get_schema_view
from drf_yasg import openapi

# API dokümantasyonu için schema_view oluşturuyoruz
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
    # Kök URL'yi otomatik /api/ dizinine yönlendiriyoruz
    path('', RedirectView.as_view(url='/api/', permanent=True)),

    # Admin paneli
    path('admin/', admin.site.urls),

    # Uygulama URL'leri, hepsi /api/ altından erişilecek
    path('api/', include('users.urls')),
    path('api/', include('bikes.urls')),
    path('api/', include('rides.urls')),
    path('api/groups/', include('groups.urls')),  # groups için ayrı prefix
    path('api/notifications/', include('notifications.urls')),  # notifications için ayrı prefix
    path('api/', include('gamification.urls')),

    # API dokümantasyonları
    path('swagger/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    path('redoc/', schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),

    # Django REST Framework login/logout sayfaları (isteğe bağlı)
    path('api/', include('rest_framework.urls', namespace='rest_framework')),
]

# DEBUG modunda medya ve statik dosyaları servis et
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
