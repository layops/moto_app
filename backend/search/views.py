from rest_framework import generics
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q
from unidecode import unidecode

from django.contrib.auth import get_user_model
from groups.models import Group
from groups.serializers import GroupSerializer
from users.serializers import UserSerializer

User = get_user_model()


class UserSearchView(generics.ListAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = super().get_queryset()
        query = self.request.query_params.get('q', None)
        if query:
            # Önce basit arama yap, sonra Python'da normalize et
            normalized_query = unidecode(query.lower())
            
            # İlk olarak basit case-insensitive arama yap
            initial_results = queryset.filter(
                Q(username__icontains=query) |
                Q(first_name__icontains=query) |
                Q(last_name__icontains=query)
            )
            
            # Sonra normalize edilmiş arama yap
            filtered_users = []
            for user in initial_results:
                normalized_username = unidecode(user.username.lower())
                normalized_first_name = unidecode(user.first_name.lower()) if user.first_name else ""
                normalized_last_name = unidecode(user.last_name.lower()) if user.last_name else ""
                
                if (normalized_query in normalized_username or
                    normalized_query in normalized_first_name or
                    normalized_query in normalized_last_name):
                    filtered_users.append(user.id)
            
            return User.objects.filter(id__in=filtered_users)
        return queryset


class GroupSearchView(generics.ListAPIView):
    queryset = Group.objects.all()
    serializer_class = GroupSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = super().get_queryset()
        query = self.request.query_params.get('q', None)
        if query:
            # Önce basit arama yap, sonra Python'da normalize et
            normalized_query = unidecode(query.lower())
            
            # İlk olarak basit case-insensitive arama yap
            initial_results = queryset.filter(
                Q(name__icontains=query) |
                Q(description__icontains=query)
            )
            
            # Sonra normalize edilmiş arama yap
            filtered_groups = []
            for group in initial_results:
                normalized_name = unidecode(group.name.lower())
                normalized_desc = unidecode(group.description.lower()) if group.description else ""
                
                if (normalized_query in normalized_name or 
                    normalized_query in normalized_desc):
                    filtered_groups.append(group.id)
            
            return Group.objects.filter(id__in=filtered_groups)
        return queryset
