from django.urls import path
from .views import (
    GeneralPostListCreateView, 
    GroupPostListCreateView, 
    PostDetailView,
    PostLikeToggleView,
    PostCommentListCreateView,
    PostCommentDetailView
)

urlpatterns = [
    path('', GeneralPostListCreateView.as_view(), name='general-post-list-create'),
    path('groups/<int:group_pk>/posts/', GroupPostListCreateView.as_view(), name='group-post-list-create'),
    path('<int:pk>/', PostDetailView.as_view(), name='post-detail'),
    path('<int:post_id>/like/', PostLikeToggleView.as_view(), name='post-like-toggle'),
    path('<int:post_id>/comments/', PostCommentListCreateView.as_view(), name='post-comment-list-create'),
    path('<int:post_id>/comments/<int:pk>/', PostCommentDetailView.as_view(), name='post-comment-detail'),
]