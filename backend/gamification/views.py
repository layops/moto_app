from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.db.models import Sum, Count, Q
from django.contrib.auth import get_user_model
from .models import Score, Achievement, UserAchievement
from .serializers import (
    AchievementSerializer, UserAchievementSerializer, 
    UserScoreSummarySerializer, LeaderboardSerializer
)

User = get_user_model()

class UserLeaderboardView(APIView):
    """Genişletilmiş liderlik tablosu - hem puan hem başarım bilgileri"""
    permission_classes = [AllowAny]
    
    def get(self, request):
        # Top 20 kullanıcıyı getir
        user_scores = (
            Score.objects.values('user__id', 'user__username')
            .annotate(total_points=Sum('points'))
            .order_by('-total_points')[:20]
        )
        
        leaderboard_data = []
        for rank, user_data in enumerate(user_scores, 1):
            user_id = user_data['user__id']
            
            # Son kazanılan başarımları getir
            recent_achievements = Achievement.objects.filter(
                user_achievements__user_id=user_id,
                user_achievements__is_unlocked=True
            ).order_by('-user_achievements__unlocked_at')[:3]
            
            leaderboard_data.append({
                'user_id': user_id,
                'username': user_data['user__username'],
                'total_points': user_data['total_points'],
                'rank': rank,
                'recent_achievements': AchievementSerializer(recent_achievements, many=True).data
            })
        
        serializer = LeaderboardSerializer(leaderboard_data, many=True)
        return Response(serializer.data)

class UserAchievementsView(APIView):
    """Kullanıcının başarımlarını getir"""
    permission_classes = [AllowAny]
    
    def get(self, request):
        # Debug: Toplam achievement sayısını kontrol et
        total_achievements = Achievement.objects.filter(is_active=True).count()
        print(f"DEBUG: Total active achievements: {total_achievements}")
        
        # Eğer hiç achievement yoksa, oluştur
        if total_achievements == 0:
            print("DEBUG: No achievements found, creating test achievement...")
            # Test için basit bir achievement oluştur
            test_achievement = Achievement.objects.create(
                name='Test Başarım',
                description='Bu bir test başarımıdır',
                icon='emoji_events',
                achievement_type='special',
                target_value=1,
                points=10,
                is_active=True
            )
            print(f"DEBUG: Created test achievement: {test_achievement.name}")
            total_achievements = Achievement.objects.filter(is_active=True).count()
            print(f"DEBUG: Total achievements now: {total_achievements}")
        
        # Tüm aktif başarımları getir (kullanıcı bazlı değil, genel)
        achievements = Achievement.objects.filter(is_active=True)
        serializer = AchievementSerializer(achievements, many=True)
        print(f"DEBUG: Serialized data: {serializer.data}")
        return Response(serializer.data)
    
    def _create_user_achievements(self, user):
        """Kullanıcı için tüm aktif başarımları oluştur"""
        active_achievements = Achievement.objects.filter(is_active=True)
        for achievement in active_achievements:
            UserAchievement.objects.get_or_create(
                user=user,
                achievement=achievement,
                defaults={'progress': 0}
            )
    
    def _create_default_achievements(self):
        """Varsayılan başarımları manuel olarak oluştur"""
        achievements_data = [
            {
                'name': 'İlk Yolculuk',
                'description': 'İlk motosiklet yolculuğunuzu tamamladınız',
                'icon': 'two_wheeler',
                'achievement_type': 'ride_count',
                'target_value': 1,
                'points': 10,
            },
            {
                'name': 'Yolcu',
                'description': '10 yolculuk tamamladınız',
                'icon': 'directions_bike',
                'achievement_type': 'ride_count',
                'target_value': 10,
                'points': 25,
            },
            {
                'name': 'Deneyimli Sürücü',
                'description': '50 yolculuk tamamladınız',
                'icon': 'motorcycle',
                'achievement_type': 'ride_count',
                'target_value': 50,
                'points': 50,
            },
            {
                'name': 'Usta Sürücü',
                'description': '100 yolculuk tamamladınız',
                'icon': 'speed',
                'achievement_type': 'ride_count',
                'target_value': 100,
                'points': 100,
            },
            {
                'name': 'Mesafe Avcısı',
                'description': '1000 km yol katettiniz',
                'icon': 'straighten',
                'achievement_type': 'distance',
                'target_value': 1000,
                'points': 75,
            },
            {
                'name': 'Hız Tutkunu',
                'description': '120 km/h hıza ulaştınız',
                'icon': 'flash_on',
                'achievement_type': 'speed',
                'target_value': 120,
                'points': 60,
            },
            {
                'name': 'Günlük Sürücü',
                'description': '7 gün üst üste yolculuk yaptınız',
                'icon': 'calendar_today',
                'achievement_type': 'streak',
                'target_value': 7,
                'points': 40,
            },
            {
                'name': 'Gece Sürücüsü',
                'description': '10 gece yolculuğu tamamladınız',
                'icon': 'nightlight_round',
                'achievement_type': 'special',
                'target_value': 10,
                'points': 35,
            },
        ]
        
        for achievement_data in achievements_data:
            Achievement.objects.get_or_create(
                name=achievement_data['name'],
                defaults=achievement_data
            )

class UserScoreSummaryView(APIView):
    """Kullanıcının puan özetini getir"""
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        user = request.user
        
        # Toplam puan
        total_points = Score.objects.filter(user=user).aggregate(
            total=Sum('points')
        )['total'] or 0
        
        # Başarım istatistikleri
        total_achievements = Achievement.objects.filter(is_active=True).count()
        unlocked_achievements = UserAchievement.objects.filter(
            user=user, is_unlocked=True
        ).count()
        
        # Sıralama
        user_rank = self._get_user_rank(user)
        
        data = {
            'user_id': user.id,
            'username': user.username,
            'total_points': total_points,
            'total_achievements': total_achievements,
            'unlocked_achievements': unlocked_achievements,
            'rank': user_rank
        }
        
        serializer = UserScoreSummarySerializer(data)
        return Response(serializer.data)
    
    def _get_user_rank(self, user):
        """Kullanıcının sıralamasını hesapla"""
        user_total = Score.objects.filter(user=user).aggregate(
            total=Sum('points')
        )['total'] or 0
        
        higher_scores = Score.objects.values('user').annotate(
            total=Sum('points')
        ).filter(total__gt=user_total).count()
        
        return higher_scores + 1

class UpdateAchievementProgressView(APIView):
    """Başarım ilerlemesini güncelle (ride tamamlandığında çağrılacak)"""
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        achievement_type = request.data.get('achievement_type')
        progress_value = request.data.get('progress_value', 1)
        
        if not achievement_type:
            return Response(
                {'error': 'achievement_type gerekli'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        user = request.user
        
        # İlgili başarımları bul ve ilerlemeyi güncelle
        achievements = Achievement.objects.filter(
            achievement_type=achievement_type,
            is_active=True
        )
        
        updated_achievements = []
        for achievement in achievements:
            user_achievement, created = UserAchievement.objects.get_or_create(
                user=user,
                achievement=achievement,
                defaults={'progress': 0}
            )
            
            # İlerlemeyi güncelle
            if achievement_type == 'ride_count':
                user_achievement.progress += progress_value
            elif achievement_type == 'distance':
                user_achievement.progress += progress_value
            elif achievement_type == 'speed':
                # Hız için maksimum değeri güncelle
                user_achievement.progress = max(user_achievement.progress, progress_value)
            
            user_achievement.save()
            updated_achievements.append(user_achievement)
        
        serializer = UserAchievementSerializer(updated_achievements, many=True)
        return Response(serializer.data)
