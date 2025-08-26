# events/urls.py dosyasını şu şekilde güncelleyin:
from django.urls import path
from .views import EventListCreateView, EventDetailView, AllEventListCreateView

urlpatterns = [
    path('', AllEventListCreateView.as_view(), name='all-events'),  # api/events/
    path('groups/<int:group_pk>/events/', EventListCreateView.as_view(), name='event-list-create'),  # api/events/groups/<group_pk>/events/
    path('groups/<int:group_pk>/events/<int:pk>/', EventDetailView.as_view(), name='event-detail'),
]