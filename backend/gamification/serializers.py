from rest_framework import serializers
from .models import Score, Group, Achievement, UserAchievement
from django.contrib.auth import get_user_model

User = get_user_model()

class GroupSerializer(serializers.ModelSerializer):
    class Meta:
        model = Group
        fields = ['id', 'name']

class ScoreSerializer(serializers.ModelSerializer):
    user_username = serializers.CharField(source='user.username', read_only=True)
    group_name = serializers.CharField(source='group.name', read_only=True)
    
    class Meta:
        model = Score
        fields = ['id', 'user', 'user_username', 'group', 'group_name', 'points', 'activity_name', 'completed_at']
        read_only_fields = ['id', 'completed_at']

class AchievementSerializer(serializers.ModelSerializer):
    class Meta:
        model = Achievement
        fields = ['id', 'name', 'description', 'icon', 'achievement_type', 'target_value', 'points', 'is_active', 'created_at']
        read_only_fields = ['id', 'created_at']

class UserAchievementSerializer(serializers.ModelSerializer):
    achievement = AchievementSerializer(read_only=True)
    achievement_id = serializers.IntegerField(write_only=True)
    user_username = serializers.CharField(source='user.username', read_only=True)
    progress_percentage = serializers.SerializerMethodField()
    
    class Meta:
        model = UserAchievement
        fields = [
            'id', 'user', 'user_username', 'achievement', 'achievement_id', 
            'progress', 'is_unlocked', 'unlocked_at', 'created_at', 'progress_percentage'
        ]
        read_only_fields = ['id', 'user', 'is_unlocked', 'unlocked_at', 'created_at']
    
    def get_progress_percentage(self, obj):
        if obj.achievement.target_value > 0:
            return min(100, (obj.progress / obj.achievement.target_value) * 100)
        return 0

class UserScoreSummarySerializer(serializers.Serializer):
    """Kullanıcının toplam puan özeti için serializer"""
    user_id = serializers.IntegerField()
    username = serializers.CharField()
    total_points = serializers.IntegerField()
    total_achievements = serializers.IntegerField()
    unlocked_achievements = serializers.IntegerField()
    rank = serializers.IntegerField(required=False)

class LeaderboardSerializer(serializers.Serializer):
    """Liderlik tablosu için serializer"""
    user_id = serializers.IntegerField()
    username = serializers.CharField()
    total_points = serializers.IntegerField()
    rank = serializers.IntegerField()
    recent_achievements = AchievementSerializer(many=True, read_only=True)
