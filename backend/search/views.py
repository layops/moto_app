from rest_framework import generics
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q

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
        print(f"🔍 UserSearchView - Query alındı: '{query}'")
        print(f"🔍 UserSearchView - Query uzunluğu: {len(query) if query else 0}")
        
        if query and len(query.strip()) >= 2:  # Minimum 2 karakter arama
            query = query.strip()
            print(f"🔍 UserSearchView - İşlenen query: '{query}'")
            
            # Tüm kullanıcılarda ara (aktif olmayanlar dahil)
            # Çünkü bazı kullanıcılar is_active=False olarak oluşturulmuş olabilir
            search_results = queryset.filter(
                Q(username__icontains=query) |
                Q(first_name__icontains=query) |
                Q(last_name__icontains=query) |
                Q(email__icontains=query)
            ).distinct().order_by('username')
            
            count = search_results.count()
            print(f"✅ UserSearchView - {count} kullanıcı bulundu")
            
            # İlk 5 sonucu log'la
            results_list = list(search_results[:5])
            for i, user in enumerate(results_list):
                print(f"   {i+1}. {user.username} - {user.first_name} {user.last_name} - {user.email}")
            
            # Sonuçları sınırla (performans için)
            return search_results[:50]
        else:
            print(f"❌ UserSearchView - Query çok kısa veya boş, boş sonuç döndürülüyor")
            return queryset.none()  # Boş sorgu için hiç sonuç döndürme


class GroupSearchView(generics.ListAPIView):
    queryset = Group.objects.all()
    serializer_class = GroupSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = super().get_queryset()
        query = self.request.query_params.get('q', None)
        print(f"🔍 GroupSearchView - Query alındı: '{query}'")
        print(f"🔍 GroupSearchView - Query uzunluğu: {len(query) if query else 0}")
        
        if query and len(query.strip()) >= 2:  # Minimum 2 karakter arama
            query = query.strip()
            print(f"🔍 GroupSearchView - İşlenen query: '{query}'")
            
            # Sadece aktif grupları ara
            search_results = queryset.filter(
                Q(name__icontains=query) |
                Q(description__icontains=query)
            ).distinct().order_by('name')
            
            count = search_results.count()
            print(f"✅ GroupSearchView - {count} grup bulundu")
            
            # İlk 5 sonucu log'la
            results_list = list(search_results[:5])
            for i, group in enumerate(results_list):
                print(f"   {i+1}. {group.name} - {group.description}")
            
            # Sonuçları sınırla (performans için)
            return search_results[:50]
        else:
            print(f"❌ GroupSearchView - Query çok kısa veya boş, boş sonuç döndürülüyor")
            return queryset.none()  # Boş sorgu için hiç sonuç döndürme
