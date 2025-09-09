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
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        user = request.user
        
        # Kullanıcının tüm başarımlarını getir (kazanılan ve kazanılmayan)
        user_achievements = UserAchievement.objects.filter(user=user).select_related('achievement')
        
        # Eğer kullanıcının hiç başarımı yoksa, tüm aktif başarımları oluştur
        if not user_achievements.exists():
            self._create_user_achievements(user)
            user_achievements = UserAchievement.objects.filter(user=user).select_related('achievement')
        
        serializer = UserAchievementSerializer(user_achievements, many=True)
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
