from django.urls import path
from .views import UserLeaderboardView

urlpatterns = [
    path('leaderboard/users/', UserLeaderboardView.as_view(), name='user-leaderboard'),
]
