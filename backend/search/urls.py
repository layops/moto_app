from django.urls import path
from .views import UserSearchView, GroupSearchView

urlpatterns = [
    path('users/', UserSearchView.as_view(), name='search-users'),
    path('groups/', GroupSearchView.as_view(), name='search-groups'),
]
