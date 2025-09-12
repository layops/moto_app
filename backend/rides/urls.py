from rest_framework.routers import DefaultRouter
from .views import (
    RideViewSet, RouteFavoriteViewSet, 
    LocationShareViewSet, RouteTemplateViewSet
)

router = DefaultRouter()
router.register(r'rides', RideViewSet, basename='ride')
router.register(r'route-favorites', RouteFavoriteViewSet, basename='route-favorite')
router.register(r'location-shares', LocationShareViewSet, basename='location-share')
router.register(r'route-templates', RouteTemplateViewSet, basename='route-template')

urlpatterns = router.urls