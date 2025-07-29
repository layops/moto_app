from rest_framework.views import APIView
from rest_framework.response import Response
from django.db.models import Sum
from .models import Score

class UserLeaderboardView(APIView):
    def get(self, request):
        user_scores = (
            Score.objects.values('user__id', 'user__username')
            .annotate(total_points=Sum('points'))
            .order_by('-total_points')[:10]
        )
        return Response(user_scores)
