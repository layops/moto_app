from django.urls import path, include
from .views import (
    GroupListCreateView, GroupDetailView, GroupMembersView,
    GroupJoinLeaveView, GroupMemberDetailView
)

urlpatterns = [
    path('', GroupListCreateView.as_view(), name='group-list-create'),
    path('<int:pk>/', GroupDetailView.as_view(), name='group-detail'),
    path('<int:pk>/members/', GroupMembersView.as_view(), name='group-members'),
    path('<int:pk>/join-leave/', GroupJoinLeaveView.as_view(), name='group-join-leave'),
    path('<int:group_pk>/members/<int:user_pk>/', GroupMemberDetailView.as_view(), name='group-member-detail'),

    # Grup alt kaynakları
    path('<int:group_pk>/posts/', include('posts.urls')),   # grup gönderileri
    path('<int:group_pk>/events/', include('events.urls')), # grup etkinlikleri
    path('<int:group_pk>/media/', include('media.urls')),   # grup medya dosyaları
]
