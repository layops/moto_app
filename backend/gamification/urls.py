from django.urls import path
from .views import (
    UserLeaderboardView, UserAchievementsView, 
    UserScoreSummaryView, UpdateAchievementProgressView
)

urlpatterns = [
    # Leaderboard
    path('leaderboard/users/', UserLeaderboardView.as_view(), name='user-leaderboard'),
    
    # Achievements
    path('achievements/', UserAchievementsView.as_view(), name='user-achievements'),
    path('achievements/update-progress/', UpdateAchievementProgressView.as_view(), name='update-achievement-progress'),
    
    # Score Summary
    path('score-summary/', UserScoreSummaryView.as_view(), name='user-score-summary'),
]
