from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import EventViewSet

router = DefaultRouter()
router.register(r'events', EventViewSet, basename='event')

# Grup bazlı nested routing
group_event_list = EventViewSet.as_view({
    'get': 'list',
    'post': 'create'
})
group_event_detail = EventViewSet.as_view({
    'get': 'retrieve',
    'patch': 'partial_update',
    'delete': 'destroy'
})
group_event_join = EventViewSet.as_view({
    'post': 'join'
})
group_event_leave = EventViewSet.as_view({
    'post': 'leave'
})

urlpatterns = [
    path('', include(router.urls)),  # /events/
    
    # /groups/<group_pk>/events/
    path('groups/<int:group_pk>/events/', group_event_list, name='group-event-list-create'),
    path('groups/<int:group_pk>/events/<int:pk>/', group_event_detail, name='group-event-detail'),
    path('groups/<int:group_pk>/events/<int:pk>/join/', group_event_join, name='group-event-join'),
    path('groups/<int:group_pk>/events/<int:pk>/leave/', group_event_leave, name='group-event-leave'),
]
