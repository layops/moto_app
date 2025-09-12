"""
PostgreSQL pg_trgm extension tabanlı arama sistemi
Bu modül kullanıcı ve grup aramaları için pg_trgm kullanır
"""
from django.contrib.auth import get_user_model
from groups.models import Group
from .models import SearchIndex
from typing import Dict, List
import time

User = get_user_model()


class PgTrgmSearchEngine:
    """
    PostgreSQL pg_trgm extension tabanlı arama motoru
    """
    
    def __init__(self):
        self.last_sync = 0
        self.sync_interval = 300  # 5 dakika
        
    def _should_sync(self):
        """
        Index'in senkronize edilip edilmeyeceğini kontrol et
        """
        return (time.time() - self.last_sync) > self.sync_interval
    
    def _sync_search_index(self):
        """
        SearchIndex'i User ve Group modelleri ile senkronize et
        """
        start_time = time.time()
        
        # Kullanıcıları senkronize et
        users = User.objects.all()
        for user in users:
            search_index, created = SearchIndex.objects.get_or_create(
                user_id=user.id,
                defaults={
                    'username': user.username,
                    'first_name': user.first_name or '',
                    'last_name': user.last_name or '',
                    'email': user.email or '',
                    'full_name': f"{user.first_name or ''} {user.last_name or ''}".strip(),
                    'search_vector': f"{user.username} {user.first_name or ''} {user.last_name or ''} {user.email or ''} {user.bio or ''} {user.motorcycle_model or ''} {user.location or ''}".strip(),
                }
            )
            
            if not created:
                # Mevcut kaydı güncelle
                search_index.username = user.username
                search_index.first_name = user.first_name or ''
                search_index.last_name = user.last_name or ''
                search_index.email = user.email or ''
                search_index.full_name = f"{user.first_name or ''} {user.last_name or ''}".strip()
                search_index.search_vector = f"{user.username} {user.first_name or ''} {user.last_name or ''} {user.email or ''} {user.bio or ''} {user.motorcycle_model or ''} {user.location or ''}".strip()
                search_index.save()
        
        # Grupları senkronize et
        groups = Group.objects.all()
        for group in groups:
            search_index, created = SearchIndex.objects.get_or_create(
                group_id=group.id,
                defaults={
                    'group_name': group.name,
                    'group_description': group.description or '',
                    'group_search_vector': f"{group.name} {group.description or ''}".strip(),
                }
            )
            
            if not created:
                # Mevcut kaydı güncelle
                search_index.group_name = group.name
                search_index.group_description = group.description or ''
                search_index.group_search_vector = f"{group.name} {group.description or ''}".strip()
                search_index.save()
        
        # Kullanılmayan kayıtları temizle
        SearchIndex.objects.filter(
            user_id__isnull=True,
            group_id__isnull=True
        ).delete()
        
        self.last_sync = time.time()
        elapsed_time = time.time() - start_time
        
    
    def _ensure_synced(self):
        """
        Search index'in güncel olduğundan emin ol
        """
        if self._should_sync():
            self._sync_search_index()
    
    def search_users(self, query: str, limit: int = 20, similarity_threshold: float = 0.3) -> List[Dict]:
        """
        pg_trgm kullanarak kullanıcı arama
        """
        if not query or len(query.strip()) < 2:
            return []
        
        self._ensure_synced()
        query = query.strip()
        
        start_time = time.time()
        
        # SearchIndex'ten arama yap
        search_results = SearchIndex.search_users(
            query=query,
            limit=limit,
            similarity_threshold=similarity_threshold
        )
        
        # Sonuçları User modelinden al ve formatla
        results = []
        for search_item in search_results:
            try:
                user = User.objects.get(id=search_item.user_id)
                user_data = {
                    'id': user.id,
                    'username': user.username,
                    'email': user.email,
                    'first_name': user.first_name or '',
                    'last_name': user.last_name or '',
                    'profile_picture': user.profile_picture,
                    'cover_picture': user.cover_picture,
                    'bio': user.bio,
                    'motorcycle_model': user.motorcycle_model,
                    'location': user.location,
                    'website': user.website,
                    'phone_number': user.phone_number,
                    'address': user.address,
                    'date_joined': user.date_joined,
                    'is_active': user.is_active,
                    'followers_count': 0,  # Bu alan için ayrı sorgu gerekebilir
                    'following_count': 0,
                    'display_name': user.first_name or user.username,
                    'join_date': user.date_joined.strftime('%B %Y'),
                    'is_following': False,
                    'similarity_score': float(search_item.max_similarity),
                }
                results.append(user_data)
            except User.DoesNotExist:
                # Kullanıcı silinmişse search index'ten de sil
                search_item.delete()
                continue
        
        elapsed_time = time.time() - start_time
        
        return results
    
    def search_groups(self, query: str, limit: int = 20, similarity_threshold: float = 0.3) -> List[Dict]:
        """
        pg_trgm kullanarak grup arama
        """
        if not query or len(query.strip()) < 2:
            return []
        
        self._ensure_synced()
        query = query.strip()
        
        start_time = time.time()
        
        # SearchIndex'ten arama yap
        search_results = SearchIndex.search_groups(
            query=query,
            limit=limit,
            similarity_threshold=similarity_threshold
        )
        
        # Sonuçları Group modelinden al ve formatla
        results = []
        for search_item in search_results:
            try:
                group = Group.objects.get(id=search_item.group_id)
                group_data = {
                    'id': group.id,
                    'name': group.name,
                    'description': group.description or '',
                    'profile_picture': group.profile_picture_url,  # Grup modelindeki alan adı
                    'member_count': group.member_count,  # Property olarak tanımlı
                    'is_public': group.is_public,
                    'owner_id': group.owner.id,
                    'owner_username': group.owner.username,
                    'created_at': group.created_at,
                    'is_active': True,  # Grup modelinde is_active alanı yok, varsayılan olarak True
                    'similarity_score': float(search_item.max_similarity),
                }
                results.append(group_data)
            except Group.DoesNotExist:
                # Grup silinmişse search index'ten de sil
                search_item.delete()
                continue
        
        elapsed_time = time.time() - start_time
        
        return results
    
    def get_user_by_id(self, user_id: int) -> Dict:
        """
        ID ile kullanıcı getir
        """
        try:
            user = User.objects.get(id=user_id)
            return {
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'first_name': user.first_name or '',
                'last_name': user.last_name or '',
                'profile_picture': user.profile_picture,
                'cover_picture': user.cover_picture,
                'bio': user.bio,
                'motorcycle_model': user.motorcycle_model,
                'location': user.location,
                'website': user.website,
                'phone_number': user.phone_number,
                'address': user.address,
                'date_joined': user.date_joined,
                'is_active': user.is_active,
            }
        except User.DoesNotExist:
            return None
    
    def get_group_by_id(self, group_id: int) -> Dict:
        """
        ID ile grup getir
        """
        try:
            group = Group.objects.get(id=group_id)
            return {
                'id': group.id,
                'name': group.name,
                'description': group.description or '',
                'created_at': group.created_at,
                'is_active': True,  # Grup modelinde is_active alanı yok, varsayılan olarak True
            }
        except Group.DoesNotExist:
            return None
    
    def clear_cache(self):
        """
        Search index'i temizle ve yeniden oluştur
        """
        SearchIndex.objects.all().delete()
        self.last_sync = 0
        self._sync_search_index()
    
    def force_sync(self):
        """
        Search index'i zorla senkronize et
        """
        self.last_sync = 0
        self._sync_search_index()


# Global instance
pg_trgm_search_engine = PgTrgmSearchEngine()
