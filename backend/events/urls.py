from django.urls import path
from .views import EventListCreateView, EventDetailView, AllEventListCreateView

urlpatterns = [
    path('events/', AllEventListCreateView.as_view(), name='all-events'),
    path('groups/<int:group_pk>/events/', EventListCreateView.as_view(), name='event-list-create'),
    path('groups/<int:group_pk>/events/<int:pk>/', EventDetailView.as_view(), name='event-detail'),
]
