# moto_app/backend/rides/views.py

from rest_framework import viewsets, status, permissions # permissions ekledik
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.utils import timezone

from .models import Ride, RideRequest # <-- RideRequest'i import edin
from .serializers import RideSerializer, RideRequestSerializer # <-- RideRequestSerializer'ı import edin
from .permissions import IsOwnerOrReadOnly

class RideViewSet(viewsets.ModelViewSet):
    queryset = Ride.objects.all()
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
        from gamification.views import UpdateAchievementProgressView
        
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