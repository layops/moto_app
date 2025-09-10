from rest_framework import generics
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
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
        
        if query and len(query.strip()) >= 2:  # Minimum 2 karakter arama
            query = query.strip()
            
            # Tüm kullanıcılarda ara (aktif olmayanlar dahil)
            # Çünkü bazı kullanıcılar is_active=False olarak oluşturulmuş olabilir
            search_results = queryset.filter(
                Q(username__icontains=query) |
                Q(first_name__icontains=query) |
                Q(last_name__icontains=query) |
                Q(email__icontains=query)
            ).distinct().order_by('username')
            
            # Sonuçları sınırla (performans için)
            return search_results[:50]
        else:
            return queryset.none()  # Boş sorgu için hiç sonuç döndürme


class GroupSearchView(generics.ListAPIView):
    queryset = Group.objects.all()
    serializer_class = GroupSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = super().get_queryset()
        query = self.request.query_params.get('q', None)
        
        if query and len(query.strip()) >= 2:  # Minimum 2 karakter arama
            query = query.strip()
            
            # Sadece aktif grupları ara
            search_results = queryset.filter(
                Q(name__icontains=query) |
                Q(description__icontains=query)
            ).distinct().order_by('name')
            
            # Sonuçları sınırla (performans için)
            return search_results[:50]
        else:
            return queryset.none()  # Boş sorgu için hiç sonuç döndürme


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_available_users(request):
    """Mevcut kullanıcıları listeler (arama için referans)"""
    users = User.objects.all()[:20]  # İlk 20 kullanıcı
    user_data = []
    for user in users:
        user_data.append({
            'id': user.id,
            'username': user.username,
            'first_name': user.first_name,
            'last_name': user.last_name,
            'full_name': f"{user.first_name} {user.last_name}".strip(),
        })
    
    return Response({
        'users': user_data,
        'total_count': User.objects.count(),
        'message': 'Arama için kullanabileceğiniz kullanıcı adları ve isimler'
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_available_groups(request):
    """Mevcut grupları listeler (arama için referans)"""
    groups = Group.objects.all()[:20]  # İlk 20 grup
    group_data = []
    for group in groups:
        group_data.append({
            'id': group.id,
            'name': group.name,
            'description': group.description,
        })
    
    return Response({
        'groups': group_data,
        'total_count': Group.objects.count(),
        'message': 'Arama için kullanabileceğiniz grup adları'
    })
