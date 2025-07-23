# groups/urls.py
from django.urls import path
from .views import GroupListCreateView, GroupDetailView, GroupAddRemoveMemberView

urlpatterns = [
    path('', GroupListCreateView.as_view(), name='group-list-create'),
    path('<int:pk>/', GroupDetailView.as_view(), name='group-detail'),
    path('<int:pk>/members/', GroupAddRemoveMemberView.as_view(), name='group-members'),
]