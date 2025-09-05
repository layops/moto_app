# C:\Users\celik\OneDrive\Belgeler\Projects\moto_app\backend\groups\urls.py

from django.urls import path, include
from .views import (
    MyGroupsListView, # <-- MyGroupsListView'i import edin
    GroupCreateView,  # <-- GroupCreateView'i import edin
    GroupDetailView, GroupMembersView,
    GroupJoinLeaveView, GroupMemberDetailView,
    DiscoverGroupsView 
)


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

    # Grup alt kaynakları
    path('<int:group_pk>/posts/', include('posts.urls')),
    path('<int:group_pk>/events/', include('events.urls')),
    path('<int:group_pk>/media/', include('media.urls')),
]