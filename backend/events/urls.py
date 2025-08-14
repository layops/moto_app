from django.urls import path
from .views import EventListCreateView, EventDetailView

urlpatterns = [
    path('groups/<int:group_pk>/events/', EventListCreateView.as_view(), name='event-list-create'),
    path('groups/<int:group_pk>/events/<int:pk>/', EventDetailView.as_view(), name='event-detail'),
]
