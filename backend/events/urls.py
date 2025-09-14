from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import EventViewSet, EventRequestDetailView

router = DefaultRouter()
router.register(r'', EventViewSet, basename='event')

urlpatterns = [
    path('', include(router.urls)),
    # EventRequest için ayrı endpoint
    path('event-requests/<int:pk>/', EventRequestDetailView.as_view(), name='event-request-detail'),
    # Participants için ayrı endpoint (DRF action çalışmazsa)
    path('<int:event_id>/participants/', EventViewSet.as_view({'get': 'participants'}), name='event-participants'),
    # Geçici: join-requests URL'si için (frontend uyumluluğu)
    path('<int:event_id>/join-requests/', EventViewSet.as_view({'get': 'requests'}), name='event-join-requests-legacy'),
]