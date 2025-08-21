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
)

urlpatterns = [
    path('register/', UserRegisterView.as_view(), name='register'),
    path('login/', UserLoginView.as_view(), name='login'),
    path('search/users/', UserSearchView.as_view(), name='user-search'),
    path('search/groups/', GroupSearchView.as_view(), name='group-search'),
    path('profile/upload-photo/', ProfileImageUploadView.as_view(), name='profile-upload-photo'),

    # Follow endpoints
    path('users/<str:username>/follow-toggle/', FollowToggleView.as_view(), name='follow-toggle'),
    path('users/<str:username>/followers/', FollowersListView.as_view(), name='followers-list'),
    path('users/<str:username>/following/', FollowingListView.as_view(), name='following-list'),
]
