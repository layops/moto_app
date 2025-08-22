from django.urls import path
from .views import GeneralPostListCreateView, GroupPostListCreateView, PostDetailView

urlpatterns = [
    path('', GeneralPostListCreateView.as_view(), name='general-post-list-create'),  # DÜZELTME: 'posts/' yerine ''
    path('groups/<int:group_pk>/posts/', GroupPostListCreateView.as_view(), name='group-post-list-create'),
    path('<int:pk>/', PostDetailView.as_view(), name='post-detail'),
]