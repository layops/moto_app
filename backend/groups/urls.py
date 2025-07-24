# moto_app/backend/groups/urls.py

from django.urls import path, include
from .views import (
    GroupListCreateView, GroupDetailView, GroupMembersView,
    GroupJoinLeaveView, GroupMemberDetailView
)

urlpatterns = [
    # Grup listeleme ve oluşturma
    path('', GroupListCreateView.as_view(), name='group-list-create'),
    # Grup detay, güncelleme ve silme
    path('<int:pk>/', GroupDetailView.as_view(), name='group-detail'),
    # Grup üyelerini listeleme ve üye ekleme/çıkarma
    path('<int:pk>/members/', GroupMembersView.as_view(), name='group-members'),
    # Gruba katılma/ayrılma (kullanıcı kendi isteğiyle)
    path('<int:pk>/join-leave/', GroupJoinLeaveView.as_view(), name='group-join-leave'),
    # Grubun belirli bir üyesinin detaylarını görme, rolünü güncelleme veya gruptan çıkarma
    path('<int:group_pk>/members/<int:user_pk>/', GroupMemberDetailView.as_view(), name='group-member-detail'),

    # Gruba ait gönderileri (posts) yönetme URL'leri
    # posts.urls içinde '', '<int:pk>/' gibi yollar olduğu için sadece include ediyoruz.
    path('<int:group_pk>/posts/', include('posts.urls')),

    # Gruba ait etkinlikleri (events) yönetme URL'leri
    # events.urls içinde '', '<int:pk>/' gibi yollar olduğu için sadece include ediyoruz.
    path('<int:group_pk>/events/', include('events.urls')),

    # Gruba ait medya dosyalarını (media) yönetme URL'leri
    # media.urls içinde '', '<int:pk>/' gibi yollar olduğu için sadece include ediyoruz.
    path('<int:group_pk>/media/', include('media.urls')), # <-- BU SATIRI EKLEYİN
]