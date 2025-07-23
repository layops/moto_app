from django.contrib import admin
from django.urls import path, include
from django.conf import settings # settings.DEBUG için gerekli
from django.conf.urls.static import static # static dosyaları sunmak için gerekli

# drf-yasg import'ları
from rest_framework import permissions
from drf_yasg.views import get_schema_view
from drf_yasg import openapi

# Eğer routerları direkt import edip kullanıyorsan aşağıdaki satırları aktif et
# from bikes.urls import router as bikes_router
# from rides.urls import router as rides_router

# schema_view tanımı, urlpatterns'den ve DEBUG kontrolünden önce olmalı
# Bu, schema_view'in her zaman erişilebilir olmasını sağlar.
schema_view = get_schema_view(
    openapi.Info(
        title="Motosiklet Bilgi Platformu API",
        default_version='v1',
        description="Motosikletlerin ve Yolculukların Yönetimi için API Dokümantasyonu",
        terms_of_service="https://www.google.com/policies/terms/", # Buraya kendi terimler sayfanı koyabilirsin
        contact=openapi.Contact(email="contact@yourdomain.com"), # Kendi e-posta adresini koyabilirsin
        license=openapi.License(name="BSD License"), # Kullanacağın lisansı belirtebilirsin
    ),
    public=True,
    permission_classes=[permissions.AllowAny], # Dokümantasyon sayfasına herkesin erişmesine izin ver
)

urlpatterns = [
    path('admin/', admin.site.urls),
    # REST Framework'ün login/logout görünümleri için (isteğe bağlı, genellikle tarayıcı API'leri için)


    # Kendi uygulama URL'leriniz
    path('api/', include('users.urls')),
    path('api/', include('bikes.urls')), # Eğer bikes_router kullandıysan 'api/', include(bikes_router.urls) olurdu
    path('api/', include('rides.urls')), # Eğer rides_router kullandıysan 'api/', include(rides_router.urls) olurdu
     path('api/groups/', include('groups.urls')),

    # API Dokümantasyon URL'leri
    path('swagger/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    path('redoc/', schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),
    path('api/', include('rest_framework.urls', namespace='rest_framework')),
]

# SADECE GELİŞTİRME ORTAMINDA (settings.DEBUG = True iken) medya/statik dosyaları sunarız.
# Bu blok, dokümantasyon URL'lerinin altına eklenmeli.
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
