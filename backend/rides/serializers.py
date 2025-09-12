# moto_app/backend/rides/serializers.py

from rest_framework import serializers
from .models import Ride, RideRequest, RouteFavorite, LocationShare, RouteTemplate
from django.conf import settings
from users.serializers import UserSerializer

# RideRequestSerializer sınıfı
class RideRequestSerializer(serializers.ModelSerializer):
    # requester alanını, kullanıcının detaylı bilgisini (username, email) göstermek için UserSerializer kullanıyoruz
    requester = UserSerializer(read_only=True)

    class Meta:
        model = RideRequest
        fields = ['id', 'ride', 'requester', 'status', 'created_at']
        read_only_fields = ['id', 'ride', 'requester', 'status', 'created_at'] # Bu alanlar API üzerinden direk değiştirilemez

# RideSerializer sınıfı
class RideSerializer(serializers.ModelSerializer):
    # Katılımcıların sadece kullanıcı adlarını göstermek için StringRelatedField kullanıyoruz
    # Bu alan, artık sadece onaylanmış katılımcıları içerecektir.
    participants = serializers.StringRelatedField(many=True, read_only=True)

    # Yolculuk sahibinin kullanıcı adını göstermek için ReadOnlyField kullanıyoruz
    owner = serializers.ReadOnlyField(source='owner.username')

    # Yeni: Yolculuk sahibinin görebileceği bekleyen istekleri listelemek için özel bir alan
    # Bu alan, sadece isteği gönderen kullanıcı yolculuğun sahibi ise doldurulur.
    pending_requests = serializers.SerializerMethodField()

    class Meta:
        model = Ride
        fields = [
            'id', 'owner', 'title', 'description', 'start_location',
            'end_location', 'start_coordinates', 'end_coordinates',
            'start_time', 'end_time', 'completed_at', 'participants',
            'max_participants', 'ride_type', 'privacy_level',
            'distance_km', 'estimated_duration_minutes',
            'is_active', 'is_favorite', 'group',
            'created_at', 'updated_at', 'pending_requests',
            'route_polyline', 'waypoints'
        ]
        read_only_fields = ('owner', 'created_at', 'updated_at', 'participants', 'pending_requests', 'completed_at')

    def get_pending_requests(self, obj):
        """
        Bu metod, pending_requests alanının nasıl doldurulacağını belirler.
        Sadece isteği yapan kullanıcı (request.user) yolculuğun sahibi ise,
        o yolculuğa ait bekleyen katılım isteklerini listeler.
        """
        # Serializer'a view'dan gelen 'request' objesini alıyoruz.
        # Bu context objesi views.py'deki 'get_serializer_context' metodundan gelir.
        request_user = self.context.get('request') # request objesinin kendisi gelir

        # Eğer istek objesi yoksa veya kullanıcı kimliği doğrulanmamışsa veya sahibi değilse
        if request_user is None or not request_user.user.is_authenticated or request_user.user != obj.owner:
            return [] # Boş liste döndür

        # Eğer istek yapan kullanıcı yolculuğun sahibi ise, bekleyen istekleri filtrele
        pending_requests = obj.requests.filter(status='pending')
        # RideRequestSerializer'ı kullanarak bu istekleri serileştiriyoruz.
        # Context'i RideRequestSerializer'a da aktarıyoruz, böylece requester alanı doğru çalışır.
        return RideRequestSerializer(pending_requests, many=True, context=self.context).data


class RouteFavoriteSerializer(serializers.ModelSerializer):
    ride = RideSerializer(read_only=True)
    
    class Meta:
        model = RouteFavorite
        fields = ['id', 'ride', 'created_at']
        read_only_fields = ['id', 'created_at']


class LocationShareSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    
    class Meta:
        model = LocationShare
        fields = [
            'id', 'user', 'ride', 'group', 'latitude', 'longitude',
            'accuracy', 'speed', 'heading', 'share_type', 'is_active',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'user', 'created_at', 'updated_at']


class RouteTemplateSerializer(serializers.ModelSerializer):
    created_by = UserSerializer(read_only=True)
    
    class Meta:
        model = RouteTemplate
        fields = [
            'id', 'name', 'description', 'category', 'route_polyline',
            'waypoints', 'start_location', 'end_location', 'distance_km',
            'estimated_duration_minutes', 'difficulty_level', 'is_public',
            'created_by', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_by', 'created_at', 'updated_at']


class CreateRideFromTemplateSerializer(serializers.Serializer):
    """Şablondan yolculuk oluşturma serializer'ı"""
    template_id = serializers.IntegerField()
    title = serializers.CharField(max_length=255)
    description = serializers.CharField(required=False, allow_blank=True)
    start_time = serializers.DateTimeField()
    max_participants = serializers.IntegerField(required=False, min_value=1)
    privacy_level = serializers.ChoiceField(choices=Ride.PRIVACY_LEVELS, default='public')
    group_id = serializers.IntegerField(required=False, allow_null=True)