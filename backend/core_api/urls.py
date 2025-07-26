from django.contrib import admin
from django.urls import path, include
from django.conf import settings # settings.DEBUG için gerekli
from django.conf.urls.static import static # static dosyaları sunmak için gerekli
from django.views.generic import RedirectView # Yeni import: RedirectView

# drf-yasg import'ları
from rest_framework import permissions
from drf_yasg.views import get_schema_view
from drf_yasg import openapi

# schema_view tanımı, urlpatterns'den ve DEBUG kontrolünden önce olmalı
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
    # Kök URL'ye erişildiğinde /api/ adresine yönlendir
    path('', RedirectView.as_view(url='/api/', permanent=True)), # <-- BU SATIRI EKLEYİN

    path('admin/', admin.site.urls),
    
    # Kendi uygulama URL'leriniz
    path('api/', include('users.urls')),
    path('api/', include('bikes.urls')),
    path('api/', include('rides.urls')),
    path('api/groups/', include('groups.urls')),
    path('api/notifications/', include('notifications.urls')),
    
    # API Dokümantasyon URL'leri (eğer kullanıyorsanız)
    path('swagger/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    path('redoc/', schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),
    
    # REST Framework'ün login/logout görünümleri için
    path('api/', include('rest_framework.urls', namespace='rest_framework')), 
]

# SADECE GELİŞTİRME ORTAMINDA (settings.DEBUG = True iken) medya/statik dosyaları sunarız.
# Bu blok, dokümantasyon URL'lerinin altına eklenmeli.
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT) 

