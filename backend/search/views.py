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
        
        print(f"🔍 UserSearchView - Query: '{query}'")
        print(f"🔍 Total users in DB: {queryset.count()}")
        
        # TÜM kullanıcıları listele (debug için)
        print(f"🔍 ALL USERS IN DATABASE:")
        for user in queryset.all():
            print(f"  - {user.username} (ID: {user.id}, Active: {user.is_active})")
        
        if query and len(query.strip()) >= 2:  # Minimum 2 karakter arama
            # Tüm kullanıcılarda ara (aktif olmayanlar dahil)
            search_results = queryset.filter(
                Q(username__icontains=query) |
                Q(first_name__icontains=query) |
                Q(last_name__icontains=query)
            ).distinct()
            
            print(f"🔍 Search results: {search_results.count()}")
            for user in search_results:
                print(f"  - {user.username} (ID: {user.id}, Active: {user.is_active})")
            
            # Sonuçları sınırla (performans için)
            return search_results[:50]
        return queryset.none()  # Boş sorgu için hiç sonuç döndürme


class GroupSearchView(generics.ListAPIView):
    queryset = Group.objects.all()
    serializer_class = GroupSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = super().get_queryset()
        query = self.request.query_params.get('q', None)
        
        if query and len(query.strip()) >= 2:  # Minimum 2 karakter arama
            # Sadece aktif grupları ara
            search_results = queryset.filter(
                Q(name__icontains=query) |
                Q(description__icontains=query)
            ).distinct()
            
            # Sonuçları sınırla (performans için)
            return search_results[:50]
        return queryset.none()  # Boş sorgu için hiç sonuç döndürme
