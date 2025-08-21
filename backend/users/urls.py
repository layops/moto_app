from django.urls import path
from .views import (
    UserRegisterView,
    UserLoginView,
    UserSearchView,
    GroupSearchView,
    ProfileImageUploadView,
    FollowToggleView,
    FollowersListView,
    FollowingListView,
    UserProfileView,
    UserPostsView,
    UserMediaView,
    UserEventsView,
)

urlpatterns = [
    # Auth ve arama
    path('register/', UserRegisterView.as_view(), name='register'),
    path('login/', UserLoginView.as_view(), name='login'),
    path('search/users/', UserSearchView.as_view(), name='user-search'),
    path('search/groups/', GroupSearchView.as_view(), name='group-search'),
    path('profile/upload-photo/', ProfileImageUploadView.as_view(), name='profile-upload-photo'),

    # Follow endpoints
    path('users/<str:username>/follow-toggle/', FollowToggleView.as_view(), name='follow-toggle'),
    path('users/<str:username>/followers/', FollowersListView.as_view(), name='followers-list'),
    path('users/<str:username>/following/', FollowingListView.as_view(), name='following-list'),

    # Kullanıcı profili ve içerikleri (Flutter uyumlu)
    path('users/<str:username>/profile/', UserProfileView.as_view(), name='user-profile'),
    path('users/<str:username>/posts/', UserPostsView.as_view(), name='user-posts'),
    path('users/<str:username>/media/', UserMediaView.as_view(), name='user-media'),
    path('users/<str:username>/events/', UserEventsView.as_view(), name='user-events'),
]
