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
    
    
    if query and len(query.strip()) >= 2:  # Minimum 2 karakter arama
        # pg_trgm extension kullanarak arama yap
        results = pg_trgm_search_engine.search_users(
            query=query,
            limit=limit,
            similarity_threshold=similarity_threshold
        )
        
        
        # İlk 5 sonucu log'la
        for i, user in enumerate(results[:5]):
            similarity = user.get('similarity_score', 0)
        
        return Response(results)
    else:
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
    
    
    if query and len(query.strip()) >= 2:  # Minimum 2 karakter arama
        # pg_trgm extension kullanarak arama yap
        results = pg_trgm_search_engine.search_groups(
            query=query,
            limit=limit,
            similarity_threshold=similarity_threshold
        )
        
        
        # İlk 5 sonucu log'la
        for i, group in enumerate(results[:5]):
            similarity = group.get('similarity_score', 0)
        
        return Response(results)
    else:
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


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def debug_search_index(request):
    """
    SearchIndex tablosundaki verileri debug et
    """
    try:
        from .models import SearchIndex
        from django.contrib.auth import get_user_model
        
        User = get_user_model()
        
        # SearchIndex'teki tüm kullanıcıları getir
        search_indexes = SearchIndex.objects.filter(user_id__isnull=False)
        
        debug_data = {
            'search_index_count': search_indexes.count(),
            'search_indexes': [],
            'users_in_db': [],
        }
        
        # SearchIndex verilerini listele
        for idx in search_indexes:
            debug_data['search_indexes'].append({
                'id': idx.id,
                'user_id': idx.user_id,
                'username': idx.username,
                'first_name': idx.first_name,
                'last_name': idx.last_name,
                'email': idx.email,
                'full_name': idx.full_name,
                'search_vector': idx.search_vector,
            })
        
        # Gerçek User tablosundaki verileri listele
        users = User.objects.all()
        for user in users:
            debug_data['users_in_db'].append({
                'id': user.id,
                'username': user.username,
                'first_name': user.first_name,
                'last_name': user.last_name,
                'email': user.email,
            })
        
        return Response(debug_data)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Debug hatası: {str(e)}'
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
