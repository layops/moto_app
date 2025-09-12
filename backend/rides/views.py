# moto_app/backend/rides/views.py

from rest_framework import viewsets, status, permissions # permissions ekledik
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.utils import timezone

from .models import Ride, RideRequest, RouteFavorite, LocationShare, RouteTemplate
from .serializers import (
    RideSerializer, RideRequestSerializer, RouteFavoriteSerializer,
    LocationShareSerializer, RouteTemplateSerializer, CreateRideFromTemplateSerializer
)
from .permissions import IsOwnerOrReadOnly

class RideViewSet(viewsets.ModelViewSet):
    queryset = Ride.objects.select_related('owner', 'group').prefetch_related('participants')
    serializer_class = RideSerializer
    permission_classes = [IsOwnerOrReadOnly]

    def get_queryset(self):
        queryset = super().get_queryset()
        start_location = self.request.query_params.get('start_location')
        if start_location:
            queryset = queryset.filter(start_location__iexact=start_location)
        return queryset

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def join(self, request, pk=None):
        """
        Kullanıcının belirli bir yolculuğa katılma isteği göndermesi için custom action.
        """
        ride = get_object_or_404(Ride, pk=pk)
        user = request.user

        # Yolculuk sahibi katılamaz (isteğe bağlı kural)
        if ride.owner == user:
            return Response(
                {"detail": "Yolculuğun sahibi katılım isteği gönderemez."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Kullanıcı zaten katılımcıysa veya bekleyen/onaylanmış isteği varsa kontrol et
        if ride.participants.filter(id=user.id).exists():
            return Response(
                {"detail": "Bu yolculuğa zaten katıldınız."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Zaten bekleyen bir istek var mı kontrol et
        if RideRequest.objects.filter(ride=ride, requester=user, status='pending').exists():
            return Response(
                {"detail": "Bu yolculuk için zaten bekleyen bir katılım isteğiniz var."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Yeni katılım isteği oluştur
        # Not: Maksimum katılımcı kontrolü onay aşamasına bırakılabilir,
        # ancak şimdilik bekleyen istekleri de engellemek için burada tutabiliriz.
        # Eğer doluluk kontrolü burada olursa, onay verildiğinde tekrar kontrol etmek gerekebilir.
        # En temiz çözüm, onay anında kontrol etmektir.
        
        # Eğer talep eden kullanıcı aynı zamanda katılımcı listesinde ise hata döndür
        if user in ride.participants.all():
            return Response(
                {"detail": "Bu yolculuğa zaten kayıtlısınız."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Yeni bir katılım isteği oluştur ve durumu 'pending' olarak ayarla
        ride_request = RideRequest.objects.create(
            ride=ride,
            requester=user,
            status='pending'
        )
        serializer = RideRequestSerializer(ride_request) # İstek serileştiricisini kullan
        return Response(
            {"detail": "Katılım isteğiniz gönderildi ve onay bekliyor.", "request": serializer.data},
            status=status.HTTP_202_ACCEPTED # Kabul edildi ama henüz işlenmedi
        )

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def leave(self, request, pk=None):
        """
        Kullanıcının belirli bir yolculuktan ayrılması için custom action.
        """
        ride = get_object_or_404(Ride, pk=pk)
        user = request.user

        # Yolculuk sahibi ayrılamaz (isteğe bağlı kural)
        if ride.owner == user:
            return Response(
                {"detail": "Yolculuğun sahibi olarak yolculuktan ayrılamazsınız. Yolculuğu iptal etmeniz gerekir."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Kullanıcı katılımcılar arasında değilse
        if not ride.participants.filter(id=user.id).exists():
            # Eğer bekleyen bir isteği varsa, onu da iptal edebiliriz
            pending_request = RideRequest.objects.filter(ride=ride, requester=user, status='pending').first()
            if pending_request:
                pending_request.status = 'cancelled' # İsteği reddet olarak işaretle
                pending_request.save()
                return Response(
                    {"detail": "Yolculuğa katılım isteğiniz iptal edildi."},
                    status=status.HTTP_200_OK
                )
            return Response(
                {"detail": "Bu yolculuğa zaten katılmamışsınız."},
                status=status.HTTP_400_BAD_REQUEST
            )

        ride.participants.remove(user)
        # Eğer onaylanmış bir isteği varsa, onu da 'cancelled' veya 'left' olarak güncelleyebiliriz
        approved_request = RideRequest.objects.filter(ride=ride, requester=user, status='approved').first()
        if approved_request:
            approved_request.status = 'cancelled' # Yolculuktan ayrılınca isteğini reddedilmiş gibi düşünebiliriz
            approved_request.save()

        serializer = self.get_serializer(ride)
        return Response(
            {"detail": "Yolculuktan başarıyla ayrıldınız.", "ride": serializer.data},
            status=status.HTTP_200_OK
        )

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def approve_request(self, request, pk=None):
        """
        Yolculuk sahibinin bir katılım isteğini onaylaması için custom action.
        URL: /api/rides/<ride_id>/approve_request/
        Body: {"request_id": <request_id>}
        """
        ride = get_object_or_404(Ride, pk=pk)

        # Sadece yolculuk sahibi onaylayabilir
        if ride.owner != request.user:
            return Response(
                {"detail": "Bu yolculuk için onaylama yetkiniz yok."},
                status=status.HTTP_403_FORBIDDEN
            )

        request_id = request.data.get('request_id')
        if not request_id:
            return Response(
                {"detail": "Onaylanacak istek ID'si belirtilmelidir."},
                status=status.HTTP_400_BAD_REQUEST
            )

        ride_request = get_object_or_404(RideRequest, id=request_id, ride=ride, status='pending')

        # Maksimum katılımcı kontrolü (onay anında)
        if ride.max_participants is not None and ride.participants.count() >= ride.max_participants:
            return Response(
                {"detail": "Üzgünüz, bu yolculuk için koltuklar dolmuştur. İstek reddedilecektir."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # İsteği onaylayın ve kullanıcıyı katılımcı olarak ekleyin
        ride_request.status = 'approved'
        ride_request.save()
        ride.participants.add(ride_request.requester)

        serializer = self.get_serializer(ride)
        return Response(
            {"detail": "Katılım isteği başarıyla onaylandı.", "ride": serializer.data},
            status=status.HTTP_200_OK
        )

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def reject_request(self, request, pk=None):
        """
        Yolculuk sahibinin bir katılım isteğini reddetmesi için custom action.
        URL: /api/rides/<ride_id>/reject_request/
        Body: {"request_id": <request_id>}
        """
        ride = get_object_or_404(Ride, pk=pk)

        # Sadece yolculuk sahibi reddedebilir
        if ride.owner != request.user:
            return Response(
                {"detail": "Bu yolculuk için reddetme yetkiniz yok."},
                status=status.HTTP_403_FORBIDDEN
            )

        request_id = request.data.get('request_id')
        if not request_id:
            return Response(
                {"detail": "Reddedilecek istek ID'si belirtilmelidir."},
                status=status.HTTP_400_BAD_REQUEST
            )

        ride_request = get_object_or_404(RideRequest, id=request_id, ride=ride, status='pending')

        # İsteği reddedin
        ride_request.status = 'rejected'
        ride_request.save()

        serializer = self.get_serializer(ride)
        return Response(
            {"detail": "Katılım isteği başarıyla reddedildi.", "ride": serializer.data},
            status=status.HTTP_200_OK
        )

    # Yolculuk sahibinin kendi yolculuklarına gelen tüm istekleri listeleyebilmesi için (isteğe bağlı)
    @action(detail=True, methods=['get'], permission_classes=[permissions.IsAuthenticated])
    def requests(self, request, pk=None):
        """
        Yolculuk sahibinin kendi yolculuğuna gelen tüm katılım isteklerini listeler.
        Sadece yolculuk sahibi erişebilir.
        """
        ride = get_object_or_404(Ride, pk=pk)

        # Sadece yolculuk sahibi kendi isteklerini görebilir
        if ride.owner != request.user:
            return Response(
                {"detail": "Bu yolculuğun isteklerini görüntüleme yetkiniz yok."},
                status=status.HTTP_403_FORBIDDEN
            )

        # Bu yolculuğa ait tüm istekleri getir
        all_requests = RideRequest.objects.filter(ride=ride).order_by('created_at')
        serializer = RideRequestSerializer(all_requests, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    @action(detail=False, methods=['get'], permission_classes=[permissions.IsAuthenticated])
    def my_requests(self, request):
        """
        Giriş yapmış kullanıcının gönderdiği tüm katılım isteklerini listeler.
        URL: /api/rides/my_requests/
        """
        # Sadece isteği yapan kullanıcının gönderdiği istekleri filtrele
        user_requests = RideRequest.objects.filter(requester=request.user).order_by('-created_at')
        serializer = RideRequestSerializer(user_requests, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def complete_ride(self, request, pk=None):
        """
        Yolculuğu tamamla ve puan/başarım ver
        URL: /api/rides/<ride_id>/complete_ride/
        Body: {
            "distance": 150,  # km
            "max_speed": 95,  # km/h
            "duration": 120   # dakika
        }
        """
        ride = get_object_or_404(Ride, pk=pk)
        user = request.user
        
        # Sadece yolculuk sahibi tamamlayabilir
        if ride.owner != user:
            return Response(
                {"detail": "Sadece yolculuk sahibi yolculuğu tamamlayabilir."},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Yolculuk zaten tamamlanmış mı kontrol et
        if hasattr(ride, 'completed_at') and ride.completed_at:
            return Response(
                {"detail": "Bu yolculuk zaten tamamlanmış."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Yolculuk verilerini al
        distance = request.data.get('distance', 0)
        max_speed = request.data.get('max_speed', 0)
        duration = request.data.get('duration', 0)
        
        # Yolculuğu tamamla
        ride.end_time = timezone.now()
        ride.save()
        
        # Puan ve başarım sistemi
        self._award_points_and_achievements(user, distance, max_speed, duration)
        
        serializer = self.get_serializer(ride)
        return Response(
            {
                "detail": "Yolculuk başarıyla tamamlandı! Puanlarınız ve başarımlarınız güncellendi.",
                "ride": serializer.data
            },
            status=status.HTTP_200_OK
        )
    
    def _award_points_and_achievements(self, user, distance, max_speed, duration):
        """Kullanıcıya puan ve başarım ver"""
        from gamification.models import Score
        
        # Temel yolculuk puanı (mesafe bazlı)
        base_points = max(10, int(distance * 0.5))  # En az 10 puan, km başına 0.5 puan
        
        # Hız bonusu
        if max_speed > 100:
            speed_bonus = int((max_speed - 100) * 0.2)
            base_points += speed_bonus
        
        # Süre bonusu (çok hızlı tamamlama)
        if duration < 60:  # 1 saatten az
            time_bonus = 20
            base_points += time_bonus
        
        # Puan ver
        Score.objects.create(
            user=user,
            points=base_points,
            activity_name=f"Ride completed: {distance}km, {max_speed}km/h"
        )
        
        # Başarım ilerlemelerini güncelle
        self._update_achievement_progress(user, distance, max_speed)
    
    def _update_achievement_progress(self, user, distance, max_speed):
        """Başarım ilerlemelerini güncelle"""
        from gamification.models import Achievement, UserAchievement
        
        # Yolculuk sayısı başarımı
        ride_count_achievements = Achievement.objects.filter(
            achievement_type='ride_count',
            is_active=True
        )
        for achievement in ride_count_achievements:
            user_achievement, created = UserAchievement.objects.get_or_create(
                user=user,
                achievement=achievement,
                defaults={'progress': 0}
            )
            user_achievement.progress += 1
            user_achievement.save()
        
        # Mesafe başarımı
        distance_achievements = Achievement.objects.filter(
            achievement_type='distance',
            is_active=True
        )
        for achievement in distance_achievements:
            user_achievement, created = UserAchievement.objects.get_or_create(
                user=user,
                achievement=achievement,
                defaults={'progress': 0}
            )
            user_achievement.progress += distance
            user_achievement.save()
        
        # Hız başarımı
        speed_achievements = Achievement.objects.filter(
            achievement_type='speed',
            is_active=True
        )
        for achievement in speed_achievements:
            user_achievement, created = UserAchievement.objects.get_or_create(
                user=user,
                achievement=achievement,
                defaults={'progress': 0}
            )
            # Hız için maksimum değeri güncelle
            user_achievement.progress = max(user_achievement.progress, max_speed)
            user_achievement.save()


class RouteFavoriteViewSet(viewsets.ModelViewSet):
    """Favori rotalar ViewSet"""
    serializer_class = RouteFavoriteSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return RouteFavorite.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        ride_id = self.request.data.get('ride_id')
        ride = get_object_or_404(Ride, id=ride_id)
        
        # Zaten favori mi kontrol et
        if RouteFavorite.objects.filter(user=self.request.user, ride=ride).exists():
            raise serializers.ValidationError("Bu rota zaten favorilerinizde.")
        
        serializer.save(user=self.request.user, ride=ride)
    
    @action(detail=False, methods=['post'])
    def toggle_favorite(self, request):
        """Favoriye ekle/çıkar"""
        ride_id = request.data.get('ride_id')
        ride = get_object_or_404(Ride, id=ride_id)
        
        favorite, created = RouteFavorite.objects.get_or_create(
            user=request.user,
            ride=ride
        )
        
        if not created:
            favorite.delete()
            return Response({"detail": "Favorilerden çıkarıldı."})
        else:
            return Response({"detail": "Favorilere eklendi."})


class LocationShareViewSet(viewsets.ModelViewSet):
    """Real-time konum paylaşımı ViewSet"""
    serializer_class = LocationShareSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return LocationShare.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
    
    @action(detail=False, methods=['get'])
    def active_shares(self, request):
        """Aktif konum paylaşımlarını getir"""
        ride_id = request.query_params.get('ride_id')
        group_id = request.query_params.get('group_id')
        
        queryset = LocationShare.objects.filter(is_active=True)
        
        if ride_id:
            queryset = queryset.filter(ride_id=ride_id)
        if group_id:
            queryset = queryset.filter(group_id=group_id)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def stop_sharing(self, request, pk=None):
        """Konum paylaşımını durdur"""
        location_share = self.get_object()
        location_share.is_active = False
        location_share.save()
        
        return Response({"detail": "Konum paylaşımı durduruldu."})


class RouteTemplateViewSet(viewsets.ModelViewSet):
    """Rota şablonları ViewSet"""
    serializer_class = RouteTemplateSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    
    def get_queryset(self):
        return RouteTemplate.objects.filter(is_public=True)
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
    
    @action(detail=False, methods=['get'])
    def by_category(self, request):
        """Kategoriye göre şablonları getir"""
        category = request.query_params.get('category')
        if category:
            templates = RouteTemplate.objects.filter(category=category, is_public=True)
        else:
            templates = RouteTemplate.objects.filter(is_public=True)
        
        serializer = self.get_serializer(templates, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def create_ride(self, request, pk=None):
        """Şablondan yolculuk oluştur"""
        template = self.get_object()
        serializer = CreateRideFromTemplateSerializer(data=request.data)
        
        if serializer.is_valid():
            ride_data = serializer.validated_data
            
            # Yolculuk oluştur
            ride = Ride.objects.create(
                owner=request.user,
                title=ride_data['title'],
                description=ride_data.get('description', ''),
                start_location=template.start_location,
                end_location=template.end_location,
                start_coordinates=template.waypoints[0] if template.waypoints else [],
                end_coordinates=template.waypoints[-1] if template.waypoints else [],
                start_time=ride_data['start_time'],
                max_participants=ride_data.get('max_participants'),
                privacy_level=ride_data.get('privacy_level', 'public'),
                ride_type='touring',
                distance_km=template.distance_km,
                estimated_duration_minutes=template.estimated_duration_minutes,
                route_polyline=template.route_polyline,
                waypoints=template.waypoints,
                group_id=ride_data.get('group_id')
            )
            
            ride_serializer = RideSerializer(ride)
            return Response(ride_serializer.data, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)