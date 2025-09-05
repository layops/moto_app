# C:\Users\celik\OneDrive\Belgeler\Projects\moto_app\backend\groups\urls.py

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    MyGroupsListView, GroupCreateView, GroupDetailView, GroupMembersView,
    GroupJoinLeaveView, GroupMemberDetailView, DiscoverGroupsView
)

# Router for ViewSets (Geçici olarak devre dışı)
# router = DefaultRouter()
# router.register(r'join-requests', GroupJoinRequestViewSet, basename='group-join-request')
# router.register(r'messages', GroupMessageViewSet, basename='group-message')
# router.register(r'posts', GroupPostViewSet, basename='group-post')


urlpatterns = [
    # REST standartlarına uygun URL'ler
    path('', GroupCreateView.as_view(), name='group-list-create'),  # POST için grup oluşturma
    path('my_groups/', MyGroupsListView.as_view(), name='my-groups'),
    path('discover/', DiscoverGroupsView.as_view(), name='discover-groups'),
    
    # Grup detay işlemleri
    path('<int:pk>/', GroupDetailView.as_view(), name='group-detail'),
    path('<int:pk>/members/', GroupMembersView.as_view(), name='group-members'),
    path('<int:pk>/join-leave/', GroupJoinLeaveView.as_view(), name='group-join-leave'),
    path('<int:group_pk>/members/<int:user_pk>/', GroupMemberDetailView.as_view(), name='group-member-detail'),

    # Grup alt kaynakları - ViewSets (Geçici olarak devre dışı)
    # path('<int:group_pk>/', include(router.urls)),
    
    # Diğer alt kaynaklar
    path('<int:group_pk>/events/', include('events.urls')),
    path('<int:group_pk>/media/', include('media.urls')),
]