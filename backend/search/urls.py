from django.urls import path
from .views import UserSearchView, GroupSearchView, get_available_users, get_available_groups, search_users, search_groups, clear_search_cache

urlpatterns = [
    path('users/', search_users, name='search-users'),
    path('groups/', search_groups, name='search-groups'),
    path('available-users/', get_available_users, name='available-users'),
    path('available-groups/', get_available_groups, name='available-groups'),
    path('clear-cache/', clear_search_cache, name='clear-search-cache'),
]
