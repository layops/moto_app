from django.urls import path
from .views import (
    UserRegisterView,
    UserLoginView,
    UserSearchView,
    GroupSearchView,
    ProfileImageUploadView,  # ekledik
)

urlpatterns = [
    path('register/', UserRegisterView.as_view(), name='register'),
    path('login/', UserLoginView.as_view(), name='login'),
    path('search/users/', UserSearchView.as_view(), name='user-search'),
    path('search/groups/', GroupSearchView.as_view(), name='group-search'),
    path('profile/upload-photo/', ProfileImageUploadView.as_view(), name='profile-upload-photo'),  # bu satır
]
