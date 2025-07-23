# users/urls.py

from django.urls import path
from rest_framework.authtoken.views import obtain_auth_token # Django'nun varsayılan login view'ı
from .views import UserRegisterView, UserLoginView # Kendi oluşturduğumuz view'ları import ediyoruz

urlpatterns = [
    # Kullanıcı kayıt API'si
    path('register/', UserRegisterView.as_view(), name='register'),
    # Kullanıcı giriş API'si (Bizim yazdığımız özel login view'ı kullanıyoruz)
    path('login/', UserLoginView.as_view(), name='login'),
    # Alternatif olarak Django REST Framework'ün kendi token oluşturma/alma view'ını da kullanabiliriz:
    # path('api-token-auth/', obtain_auth_token, name='api_token_auth'),
]