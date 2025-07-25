from django.urls import path
from rest_framework.authtoken.views import obtain_auth_token 
from .views import UserRegisterView, UserLoginView, UserSearchView, GroupSearchView # Yeni arama görünümleri import edildi

urlpatterns = [
    # Kullanıcı kayıt API'si
    path('register/', UserRegisterView.as_view(), name='register'),
    # Kullanıcı giriş API'si
    path('login/', UserLoginView.as_view(), name='login'),
    
    # Kullanıcı arama API'si
    path('search/users/', UserSearchView.as_view(), name='user-search'),
    # Grup arama API'si
    path('search/groups/', GroupSearchView.as_view(), name='group-search'),

    # Alternatif olarak Django REST Framework'ün kendi token oluşturma/alma view'ını da kullanabiliriz:
    # path('api-token-auth/', obtain_auth_token, name='api_token_auth'),
]
