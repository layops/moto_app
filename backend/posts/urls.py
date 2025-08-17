# moto_app/backend/posts/urls.py

from django.urls import path
from .views import GeneralPostListCreateView, GroupPostListCreateView, PostDetailView

urlpatterns = [
    path('posts/', GeneralPostListCreateView.as_view(), name='general-post-list-create'),
    path('groups/<int:group_pk>/posts/', GroupPostListCreateView.as_view(), name='group-post-list-create'),
    path('posts/<int:pk>/', PostDetailView.as_view(), name='post-detail'),
]