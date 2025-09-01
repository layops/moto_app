# users/urls.py
from django.urls import path
from .views import (
    UserRegisterView,
    UserLoginView,
    ProfileImageUploadView,
    CoverImageUploadView, # Yeni eklendi
    FollowToggleView,
    FollowersListView,
    FollowingListView,
    UserProfileView,
    UserPostsView,
    UserMediaView,
    UserEventsView
)

urlpatterns = [
    # Register / Login
    path('register/', UserRegisterView.as_view(), name='user-register'),
    path('login/', UserLoginView.as_view(), name='user-login'),

    # Profile Image Upload
    path('<str:username>/upload-photo/', ProfileImageUploadView.as_view(), name='profile-upload-photo'),
    path('<str:username>/upload-cover/', CoverImageUploadView.as_view(), name='profile-upload-cover'), # Yeni URL

    # Follow / Followers / Following
    path('<str:username>/follow-toggle/', FollowToggleView.as_view(), name='follow-toggle-by-username'),
    path('<int:user_id>/follow-toggle/', FollowToggleView.as_view(), name='follow-toggle-by-id'),
    path('<str:username>/followers/', FollowersListView.as_view(), name='followers-list'),
    path('<str:username>/following/', FollowingListView.as_view(), name='following-list'),

    # User Profile
    path('<str:username>/profile/', UserProfileView.as_view(), name='user-profile'),

    # User Posts
    path('<str:username>/posts/', UserPostsView.as_view(), name='user-posts'),

    # User Media
    path('<str:username>/media/', UserMediaView.as_view(), name='user-media'),

    # User Events
    path('<str:username>/events/', UserEventsView.as_view(), name='user-events'),
]