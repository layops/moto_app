from django.urls import path
from .views import (
    EventListCreateView, 
    EventDetailView, 
    AllEventListCreateView,
    EventJoinView,
    EventLeaveView
)

urlpatterns = [
    path('', AllEventListCreateView.as_view(), name='all-events'),
    path('groups/<int:group_pk>/events/', EventListCreateView.as_view(), name='event-list-create'),
    path('groups/<int:group_pk>/events/<int:pk>/', EventDetailView.as_view(), name='event-detail'),
    path('events/<int:pk>/join/', EventJoinView.as_view(), name='event-join'),
    path('events/<int:pk>/leave/', EventLeaveView.as_view(), name='event-leave'),
]
