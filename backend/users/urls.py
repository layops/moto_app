# moto_app/backend/users/urls.py

from django.urls import path
from .views import (
    UserRegisterView,
    UserLoginView,
    ProfileImageUploadView,
    FollowToggleView,
    FollowersListView,
    FollowingListView,
    UserProfileView,
    UserPostsView,
    UserMediaView,
    UserEventsView,
    UserProfileUpdateView,
)

urlpatterns = [
    # Register & Login
    path('register/', UserRegisterView.as_view(), name='register'),
    path('login/', UserLoginView.as_view(), name='login'),

    # Profile
    path('<str:username>/profile/', UserProfileView.as_view(), name='user-profile'),
    path('profile/update/', UserProfileUpdateView.as_view(), name='profile-update'),
    path('profile/upload-photo/', ProfileImageUploadView.as_view(), name='profile-upload-photo'),

    # Follow system
    path('<str:username>/follow-toggle/', FollowToggleView.as_view(), name='follow-toggle'),
    path('<str:username>/followers/', FollowersListView.as_view(), name='followers-list'),
    path('<str:username>/following/', FollowingListView.as_view(), name='following-list'),

    # User content
    path('<str:username>/posts/', UserPostsView.as_view(), name='user-posts'),
    path('<str:username>/media/', UserMediaView.as_view(), name='user-media'),
    path('<str:username>/events/', UserEventsView.as_view(), name='user-events'),
]