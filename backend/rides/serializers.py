# moto_app/backend/rides/serializers.py

from rest_framework import serializers
from .models import Ride, RideRequest
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
            'end_location', 'start_time', 'end_time', 'participants',
            'max_participants', 'is_active', 'created_at', 'updated_at',
            'pending_requests',
            'route_polyline',  # <-- Yeni eklenen alan
            'waypoints'        # <-- Yeni eklenen alan
        ]
        # 'participants' alanı artık doğrudan API üzerinden değiştirilmez.
        # owner, created_at, updated_at gibi alanlar da sadece okunabilir.
        read_only_fields = ('owner', 'created_at', 'updated_at', 'participants', 'pending_requests')

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