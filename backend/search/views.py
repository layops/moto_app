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
        # Her seferinde fresh queryset al
        queryset = User.objects.all()
        query = self.request.query_params.get('q', None)
        
        print(f"🔍 UserSearchView - Query: '{query}'")
        print(f"🔍 UserSearchView - Request user: {self.request.user}")
        print(f"🔍 UserSearchView - Total users in DB: {User.objects.count()}")
        print(f"🔍 UserSearchView - All query params: {dict(self.request.query_params)}")
        
        if query and len(query.strip()) >= 2:  # Minimum 2 karakter arama
            query = query.strip()
            
            # Tüm kullanıcıları listele (debug için)
            all_users = User.objects.all()
            print(f"🔍 UserSearchView - All users in DB:")
            for user in all_users:
                print(f"   - ID: {user.id}, Username: '{user.username}', First: '{user.first_name}', Last: '{user.last_name}', Email: '{user.email}'")
            
            # Arama kriterlerini ayrı ayrı test et ve log'la
            username_matches = User.objects.filter(username__icontains=query)
            first_name_matches = User.objects.filter(first_name__icontains=query)
            last_name_matches = User.objects.filter(last_name__icontains=query)
            email_matches = User.objects.filter(email__icontains=query)
            
            print(f"🔍 UserSearchView - Username matches for '{query}': {username_matches.count()}")
            for user in username_matches:
                print(f"   - {user.username}")
            
            print(f"🔍 UserSearchView - First name matches for '{query}': {first_name_matches.count()}")
            for user in first_name_matches:
                print(f"   - {user.first_name}")
            
            print(f"🔍 UserSearchView - Last name matches for '{query}': {last_name_matches.count()}")
            for user in last_name_matches:
                print(f"   - {user.last_name}")
            
            print(f"🔍 UserSearchView - Email matches for '{query}': {email_matches.count()}")
            for user in email_matches:
                print(f"   - {user.email}")
            
            # Tüm kullanıcılarda ara (aktif olmayanlar dahil)
            # Çünkü bazı kullanıcılar is_active=False olarak oluşturulmuş olabilir
            search_results = User.objects.filter(
                Q(username__icontains=query) |
                Q(first_name__icontains=query) |
                Q(last_name__icontains=query) |
                Q(email__icontains=query)
            ).distinct().order_by('username')
            
            count = search_results.count()
            print(f"✅ UserSearchView - Found {count} users for query '{query}'")
            
            # İlk 5 sonucu log'la
            results_list = list(search_results[:5])
            for i, user in enumerate(results_list):
                print(f"   {i+1}. {user.username} - {user.first_name} {user.last_name} - {user.email}")
            
            # Sonuçları sınırla (performans için)
            return search_results[:50]
        else:
            print(f"❌ UserSearchView - Query too short or empty")
            return User.objects.none()  # Boş sorgu için hiç sonuç döndürme


class GroupSearchView(generics.ListAPIView):
    queryset = Group.objects.all()
    serializer_class = GroupSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = super().get_queryset()
        query = self.request.query_params.get('q', None)
        
        print(f"🔍 GroupSearchView - Query: '{query}'")
        print(f"🔍 GroupSearchView - Request user: {self.request.user}")
        print(f"🔍 GroupSearchView - Total groups in DB: {Group.objects.count()}")
        
        if query and len(query.strip()) >= 2:  # Minimum 2 karakter arama
            query = query.strip()
            
            # Sadece aktif grupları ara
            search_results = queryset.filter(
                Q(name__icontains=query) |
                Q(description__icontains=query)
            ).distinct().order_by('name')
            
            count = search_results.count()
            print(f"✅ GroupSearchView - Found {count} groups for query '{query}'")
            
            # İlk 5 sonucu log'la
            results_list = list(search_results[:5])
            for i, group in enumerate(results_list):
                print(f"   {i+1}. {group.name} - {group.description}")
            
            # Sonuçları sınırla (performans için)
            return search_results[:50]
        else:
            print(f"❌ GroupSearchView - Query too short or empty")
            return queryset.none()  # Boş sorgu için hiç sonuç döndürme


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_available_users(request):
    """Mevcut kullanıcıları listeler (arama için referans)"""
    print(f"🔍 get_available_users - Request user: {request.user}")
    print(f"🔍 get_available_users - Total users in DB: {User.objects.count()}")
    
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
        print(f"   - {user.username} ({user.first_name} {user.last_name})")
    
    print(f"✅ get_available_users - Returning {len(user_data)} users")
    
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
