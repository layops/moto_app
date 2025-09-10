"""
Hash tablosu tabanlı arama sistemi
Bu modül kullanıcı ve grup aramaları için hash tablosu kullanır
"""
from django.contrib.auth import get_user_model
from groups.models import Group
from typing import Dict, List, Set
import time

User = get_user_model()

class HashSearchEngine:
    """
    Hash tablosu tabanlı arama motoru
    """
    
    def __init__(self):
        self.user_hash_table = {}
        self.group_hash_table = {}
        self.username_index = {}
        self.email_index = {}
        self.first_name_index = {}
        self.last_name_index = {}
        self.group_name_index = {}
        self.last_update = 0
        self.update_interval = 300  # 5 dakika
        
    def _build_hash_tables(self):
        """
        Hash tablolarını oluştur
        """
        print("🔍 HashSearchEngine - Hash tabloları oluşturuluyor...")
        start_time = time.time()
        
        # Kullanıcı hash tablosu
        users = User.objects.all()
        self.user_hash_table = {}
        self.username_index = {}
        self.email_index = {}
        self.first_name_index = {}
        self.last_name_index = {}
        
        for user in users:
            # Ana hash tablosu
            self.user_hash_table[user.id] = {
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
            
            # Username index (tam eşleşme)
            self.username_index[user.username.lower()] = user.id
            
            # Email index (tam eşleşme)
            if user.email:
                self.email_index[user.email.lower()] = user.id
            
            # İsim indexleri (kısmi eşleşme için)
            if user.first_name:
                first_name_lower = user.first_name.lower()
                if first_name_lower not in self.first_name_index:
                    self.first_name_index[first_name_lower] = set()
                self.first_name_index[first_name_lower].add(user.id)
            
            if user.last_name:
                last_name_lower = user.last_name.lower()
                if last_name_lower not in self.last_name_index:
                    self.last_name_index[last_name_lower] = set()
                self.last_name_index[last_name_lower].add(user.id)
        
        # Grup hash tablosu
        groups = Group.objects.all()
        self.group_hash_table = {}
        self.group_name_index = {}
        
        for group in groups:
            self.group_hash_table[group.id] = {
                'id': group.id,
                'name': group.name,
                'description': group.description or '',
                'created_at': group.created_at,
                'is_active': group.is_active,
            }
            
            # Grup adı index
            group_name_lower = group.name.lower()
            if group_name_lower not in self.group_name_index:
                self.group_name_index[group_name_lower] = set()
            self.group_name_index[group_name_lower].add(group.id)
        
        self.last_update = time.time()
        elapsed_time = time.time() - start_time
        
        print(f"✅ HashSearchEngine - Hash tabloları oluşturuldu:")
        print(f"   - Kullanıcılar: {len(self.user_hash_table)}")
        print(f"   - Gruplar: {len(self.group_hash_table)}")
        print(f"   - Süre: {elapsed_time:.3f} saniye")
    
    def _should_update(self):
        """
        Hash tablolarının güncellenip güncellenmeyeceğini kontrol et
        """
        return (time.time() - self.last_update) > self.update_interval
    
    def _ensure_updated(self):
        """
        Hash tablolarının güncel olduğundan emin ol
        """
        if not self.user_hash_table or self._should_update():
            self._build_hash_tables()
    
    def search_users(self, query: str) -> List[Dict]:
        """
        Kullanıcı arama - hash tablosu kullanarak
        """
        if not query or len(query.strip()) < 2:
            return []
        
        self._ensure_updated()
        query = query.strip().lower()
        
        print(f"🔍 HashSearchEngine - Kullanıcı arama: '{query}'")
        start_time = time.time()
        
        found_user_ids = set()
        
        # 1. Tam username eşleşmesi (en hızlı)
        if query in self.username_index:
            found_user_ids.add(self.username_index[query])
            print(f"   ✅ Tam username eşleşmesi: {query}")
        
        # 2. Tam email eşleşmesi
        if query in self.email_index:
            found_user_ids.add(self.email_index[query])
            print(f"   ✅ Tam email eşleşmesi: {query}")
        
        # 3. Kısmi eşleşmeler
        # Username'de arama
        for username, user_id in self.username_index.items():
            if query in username:
                found_user_ids.add(user_id)
        
        # First name'de arama
        for first_name, user_ids in self.first_name_index.items():
            if query in first_name:
                found_user_ids.update(user_ids)
        
        # Last name'de arama
        for last_name, user_ids in self.last_name_index.items():
            if query in last_name:
                found_user_ids.update(user_ids)
        
        # 4. Email'de arama
        for email, user_id in self.email_index.items():
            if query in email:
                found_user_ids.add(user_id)
        
        # Sonuçları hazırla
        results = []
        for user_id in found_user_ids:
            if user_id in self.user_hash_table:
                user_data = self.user_hash_table[user_id].copy()
                # Ek alanları ekle
                user_data['followers_count'] = 0  # Bu alan için ayrı sorgu gerekebilir
                user_data['following_count'] = 0
                user_data['display_name'] = user_data['first_name']
                user_data['join_date'] = user_data['date_joined'].strftime('%B %Y')
                user_data['is_following'] = False
                results.append(user_data)
        
        elapsed_time = time.time() - start_time
        print(f"✅ HashSearchEngine - {len(results)} kullanıcı bulundu ({elapsed_time:.3f} saniye)")
        
        return results
    
    def search_groups(self, query: str) -> List[Dict]:
        """
        Grup arama - hash tablosu kullanarak
        """
        if not query or len(query.strip()) < 2:
            return []
        
        self._ensure_updated()
        query = query.strip().lower()
        
        print(f"🔍 HashSearchEngine - Grup arama: '{query}'")
        start_time = time.time()
        
        found_group_ids = set()
        
        # 1. Tam grup adı eşleşmesi
        if query in self.group_name_index:
            found_group_ids.update(self.group_name_index[query])
            print(f"   ✅ Tam grup adı eşleşmesi: {query}")
        
        # 2. Kısmi eşleşmeler
        for group_name, group_ids in self.group_name_index.items():
            if query in group_name:
                found_group_ids.update(group_ids)
        
        # Sonuçları hazırla
        results = []
        for group_id in found_group_ids:
            if group_id in self.group_hash_table:
                results.append(self.group_hash_table[group_id].copy())
        
        elapsed_time = time.time() - start_time
        print(f"✅ HashSearchEngine - {len(results)} grup bulundu ({elapsed_time:.3f} saniye)")
        
        return results
    
    def get_user_by_id(self, user_id: int) -> Dict:
        """
        ID ile kullanıcı getir
        """
        self._ensure_updated()
        return self.user_hash_table.get(user_id)
    
    def get_group_by_id(self, group_id: int) -> Dict:
        """
        ID ile grup getir
        """
        self._ensure_updated()
        return self.group_hash_table.get(group_id)
    
    def clear_cache(self):
        """
        Hash tablolarını temizle
        """
        self.user_hash_table = {}
        self.group_hash_table = {}
        self.username_index = {}
        self.email_index = {}
        self.first_name_index = {}
        self.last_name_index = {}
        self.group_name_index = {}
        self.last_update = 0
        print("🗑️ HashSearchEngine - Cache temizlendi")


# Global instance
hash_search_engine = HashSearchEngine()
