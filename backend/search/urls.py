from django.urls import path
from .views import UserSearchView, GroupSearchView, get_available_users, get_available_groups

urlpatterns = [
    path('users/', UserSearchView.as_view(), name='search-users'),
    path('groups/', GroupSearchView.as_view(), name='search-groups'),
    path('available-users/', get_available_users, name='available-users'),
    path('available-groups/', get_available_groups, name='available-groups'),
]
