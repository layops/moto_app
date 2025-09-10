from django.db import models
from django.contrib.postgres.indexes import GinIndex
from django.contrib.postgres.search import TrigramSimilarity


class SearchIndex(models.Model):
    """
    Arama için optimize edilmiş index modeli
    pg_trgm extension ile trigram tabanlı arama yapar
    """
    
    # Kullanıcı arama indexi
    user_id = models.IntegerField(unique=True, null=True, blank=True)
    username = models.CharField(max_length=150, db_index=True)
    first_name = models.CharField(max_length=150, blank=True)
    last_name = models.CharField(max_length=150, blank=True)
    email = models.EmailField(blank=True)
    full_name = models.CharField(max_length=300, blank=True)  # first_name + last_name
    search_vector = models.TextField(blank=True)  # Tüm arama alanlarının birleşimi
    
    # Grup arama indexi
    group_id = models.IntegerField(unique=True, null=True, blank=True)
    group_name = models.CharField(max_length=200, blank=True)
    group_description = models.TextField(blank=True)
    group_search_vector = models.TextField(blank=True)  # Grup arama alanlarının birleşimi
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'search_index'
        indexes = [
            # Trigram indexleri - pg_trgm için optimize edilmiş
            GinIndex(fields=['username'], name='search_username_gin_idx'),
            GinIndex(fields=['first_name'], name='search_first_name_gin_idx'),
            GinIndex(fields=['last_name'], name='search_last_name_gin_idx'),
            GinIndex(fields=['full_name'], name='search_full_name_gin_idx'),
            GinIndex(fields=['email'], name='search_email_gin_idx'),
            GinIndex(fields=['group_name'], name='search_group_name_gin_idx'),
            GinIndex(fields=['group_description'], name='search_group_desc_gin_idx'),
            GinIndex(fields=['search_vector'], name='search_vector_gin_idx'),
            GinIndex(fields=['group_search_vector'], name='search_group_vector_gin_idx'),
        ]
    
    def __str__(self):
        if self.user_id:
            return f"User Search Index: {self.username}"
        elif self.group_id:
            return f"Group Search Index: {self.group_name}"
        return f"Search Index: {self.id}"
    
    @classmethod
    def search_users(cls, query, limit=20, similarity_threshold=0.3):
        """
        pg_trgm kullanarak kullanıcı arama
        """
        from django.db.models import Q, F
        from django.contrib.postgres.search import TrigramSimilarity
        
        if not query or len(query.strip()) < 2:
            return cls.objects.none()
        
        query = query.strip()
        
        # Trigram similarity ile arama
        return cls.objects.filter(
            user_id__isnull=False
        ).annotate(
            # Her alan için similarity hesapla
            username_similarity=TrigramSimilarity('username', query),
            first_name_similarity=TrigramSimilarity('first_name', query),
            last_name_similarity=TrigramSimilarity('last_name', query),
            full_name_similarity=TrigramSimilarity('full_name', query),
            email_similarity=TrigramSimilarity('email', query),
            search_vector_similarity=TrigramSimilarity('search_vector', query),
        ).filter(
            # En az bir alanda threshold'u geçen sonuçlar
            Q(username_similarity__gte=similarity_threshold) |
            Q(first_name_similarity__gte=similarity_threshold) |
            Q(last_name_similarity__gte=similarity_threshold) |
            Q(full_name_similarity__gte=similarity_threshold) |
            Q(email_similarity__gte=similarity_threshold) |
            Q(search_vector_similarity__gte=similarity_threshold)
        ).annotate(
            # En yüksek similarity'yi hesapla
            max_similarity=models.functions.Greatest(
                'username_similarity',
                'first_name_similarity', 
                'last_name_similarity',
                'full_name_similarity',
                'email_similarity',
                'search_vector_similarity'
            )
        ).order_by('-max_similarity')[:limit]
    
    @classmethod
    def search_groups(cls, query, limit=20, similarity_threshold=0.3):
        """
        pg_trgm kullanarak grup arama
        """
        from django.db.models import Q, F
        from django.contrib.postgres.search import TrigramSimilarity
        
        if not query or len(query.strip()) < 2:
            return cls.objects.none()
        
        query = query.strip()
        
        # Trigram similarity ile arama
        return cls.objects.filter(
            group_id__isnull=False
        ).annotate(
            # Her alan için similarity hesapla
            group_name_similarity=TrigramSimilarity('group_name', query),
            group_desc_similarity=TrigramSimilarity('group_description', query),
            group_vector_similarity=TrigramSimilarity('group_search_vector', query),
        ).filter(
            # En az bir alanda threshold'u geçen sonuçlar
            Q(group_name_similarity__gte=similarity_threshold) |
            Q(group_desc_similarity__gte=similarity_threshold) |
            Q(group_vector_similarity__gte=similarity_threshold)
        ).annotate(
            # En yüksek similarity'yi hesapla
            max_similarity=models.functions.Greatest(
                'group_name_similarity',
                'group_desc_similarity',
                'group_vector_similarity'
            )
        ).order_by('-max_similarity')[:limit]
