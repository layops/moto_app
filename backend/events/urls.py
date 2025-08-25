# events/urls.py
from django.urls import path
from .views import EventListCreateView, EventDetailView, AllEventListView

urlpatterns = [
    path('events/', AllEventListView.as_view(), name='all-events'),  # Yeni endpoint
    path('groups/<int:group_pk>/events/', EventListCreateView.as_view(), name='event-list-create'),
    path('groups/<int:group_pk>/events/<int:pk>/', EventDetailView.as_view(), name='event-detail'),
]