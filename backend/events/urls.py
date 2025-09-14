from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import EventViewSet, EventRequestDetailView

router = DefaultRouter()
router.register(r'', EventViewSet, basename='event')

urlpatterns = [
    path('', include(router.urls)),
    # EventRequest için ayrı endpoint
    path('event-requests/<int:pk>/', EventRequestDetailView.as_view(), name='event-request-detail'),
]