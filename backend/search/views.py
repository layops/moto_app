from rest_framework import generics
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.db.models import Q
from django.views.decorators.cache import never_cache
from django.utils.decorators import method_decorator

from django.contrib.auth import get_user_model
from groups.models import Group
from groups.serializers import GroupSerializer
from users.serializers import UserSerializer
from .pg_trgm_search import pg_trgm_search_engine

User = get_user_model()


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def search_users(request):
    """
    Kullanıcı arama endpoint'i - pg_trgm extension kullanarak
    """
    query = request.query_params.get('q', None)
    limit = int(request.query_params.get('limit', 20))
    similarity_threshold = float(request.query_params.get('threshold', 0.3))
    
    print(f"🔍 search_users - Query: '{query}', Limit: {limit}, Threshold: {similarity_threshold}")
    print(f"🔍 search_users - Request user: {request.user}")
    
    if query and len(query.strip()) >= 2:  # Minimum 2 karakter arama
        # pg_trgm extension kullanarak arama yap
        results = pg_trgm_search_engine.search_users(
            query=query,
            limit=limit,
            similarity_threshold=similarity_threshold
        )
        
        print(f"✅ search_users - pg_trgm ile {len(results)} kullanıcı bulundu")
        
        # İlk 5 sonucu log'la
        for i, user in enumerate(results[:5]):
            similarity = user.get('similarity_score', 0)
            print(f"   {i+1}. {user['username']} - {user['first_name']} {user['last_name']} - {user['email']} (similarity: {similarity:.3f})")
        
        return Response(results)
    else:
        print(f"❌ search_users - Query too short or empty")
        return Response([])  # Boş sorgu için hiç sonuç döndürme


@method_decorator(never_cache, name='dispatch')
class UserSearchView(generics.ListAPIView):
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        # Bu view artık kullanılmıyor, search_users function'ı kullanılıyor
        return User.objects.none()


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def search_groups(request):
    """
    Grup arama endpoint'i - pg_trgm extension kullanarak
    """
    query = request.query_params.get('q', None)
    limit = int(request.query_params.get('limit', 20))
    similarity_threshold = float(request.query_params.get('threshold', 0.3))
    
    print(f"🔍 search_groups - Query: '{query}', Limit: {limit}, Threshold: {similarity_threshold}")
    print(f"🔍 search_groups - Request user: {request.user}")
    
    if query and len(query.strip()) >= 2:  # Minimum 2 karakter arama
        # pg_trgm extension kullanarak arama yap
        results = pg_trgm_search_engine.search_groups(
            query=query,
            limit=limit,
            similarity_threshold=similarity_threshold
        )
        
        print(f"✅ search_groups - pg_trgm ile {len(results)} grup bulundu")
        
        # İlk 5 sonucu log'la
        for i, group in enumerate(results[:5]):
            similarity = group.get('similarity_score', 0)
            print(f"   {i+1}. {group['name']} - {group['description']} (similarity: {similarity:.3f})")
        
        return Response(results)
    else:
        print(f"❌ search_groups - Query too short or empty")
        return Response([])  # Boş sorgu için hiç sonuç döndürme


@method_decorator(never_cache, name='dispatch')
class GroupSearchView(generics.ListAPIView):
    serializer_class = GroupSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        # Bu view artık kullanılmıyor, search_groups function'ı kullanılıyor
        return Group.objects.none()


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


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def clear_search_cache(request):
    """
    pg_trgm search index cache'ini temizle
    """
    try:
        pg_trgm_search_engine.clear_cache()
        return Response({
            'success': True,
            'message': 'Arama cache\'i başarıyla temizlendi ve yeniden oluşturuldu'
        })
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Cache temizleme hatası: {str(e)}'
        }, status=500)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def sync_search_index(request):
    """
    Search index'i zorla senkronize et
    """
    try:
        pg_trgm_search_engine.force_sync()
        return Response({
            'success': True,
            'message': 'Search index başarıyla senkronize edildi'
        })
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Senkronizasyon hatası: {str(e)}'
        }, status=500)
