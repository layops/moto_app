# PostgreSQL pg_trgm Arama Sistemi

Bu modül, PostgreSQL'in `pg_trgm` extension'ını kullanarak gelişmiş arama özellikleri sağlar.

## Özellikler

- **Trigram Tabanlı Arama**: PostgreSQL'in `pg_trgm` extension'ı ile hızlı ve doğru arama
- **Similarity Scoring**: Arama sonuçlarında benzerlik skorları
- **GIN Indexleri**: Arama performansı için optimize edilmiş indexler
- **Otomatik Senkronizasyon**: User ve Group modelleri ile otomatik senkronizasyon
- **Yapılandırılabilir Threshold**: Arama hassasiyetini ayarlayabilme

## Kurulum

### 1. PostgreSQL Extension'ını Etkinleştir

```bash
# Migration'ları çalıştır
python manage.py migrate search
```

### 2. Search Index'i Senkronize Et

```bash
# İlk kez senkronizasyon
python manage.py sync_search_index --force

# Normal senkronizasyon
python manage.py sync_search_index
```

## API Endpoints

### Kullanıcı Arama

```
GET /api/search/users/?q=arama_terimi&limit=20&threshold=0.3
```

**Parametreler:**
- `q`: Arama terimi (minimum 2 karakter)
- `limit`: Maksimum sonuç sayısı (varsayılan: 20)
- `threshold`: Benzerlik eşiği (varsayılan: 0.3)

### Grup Arama

```
GET /api/search/groups/?q=arama_terimi&limit=20&threshold=0.3
```

**Parametreler:**
- `q`: Arama terimi (minimum 2 karakter)
- `limit`: Maksimum sonuç sayısı (varsayılan: 20)
- `threshold`: Benzerlik eşiği (varsayılan: 0.3)

### Cache Yönetimi

```
POST /api/search/clear-cache/     # Cache'i temizle ve yeniden oluştur
POST /api/search/sync-index/      # Index'i zorla senkronize et
```

## Model Yapısı

### SearchIndex Modeli

```python
class SearchIndex(models.Model):
    # Kullanıcı alanları
    user_id = models.IntegerField(unique=True, null=True, blank=True)
    username = models.CharField(max_length=150, db_index=True)
    first_name = models.CharField(max_length=150, blank=True)
    last_name = models.CharField(max_length=150, blank=True)
    email = models.EmailField(blank=True)
    full_name = models.CharField(max_length=300, blank=True)
    search_vector = models.TextField(blank=True)
    
    # Grup alanları
    group_id = models.IntegerField(unique=True, null=True, blank=True)
    group_name = models.CharField(max_length=200, blank=True)
    group_description = models.TextField(blank=True)
    group_search_vector = models.TextField(blank=True)
```

## Performans Optimizasyonları

### GIN Indexleri

Model, aşağıdaki alanlar için GIN indexleri kullanır:
- `username`
- `first_name`
- `last_name`
- `full_name`
- `email`
- `group_name`
- `group_description`
- `search_vector`
- `group_search_vector`

### Otomatik Senkronizasyon

- Her 5 dakikada bir otomatik senkronizasyon
- User veya Group modeli değiştiğinde manuel senkronizasyon gerekebilir
- `sync_search_index` management command ile manuel senkronizasyon

## Kullanım Örnekleri

### Python'da Arama

```python
from search.pg_trgm_search import pg_trgm_search_engine

# Kullanıcı arama
users = pg_trgm_search_engine.search_users(
    query="ahmet",
    limit=10,
    similarity_threshold=0.4
)

# Grup arama
groups = pg_trgm_search_engine.search_groups(
    query="motor",
    limit=5,
    similarity_threshold=0.3
)
```

### Django ORM ile Arama

```python
from search.models import SearchIndex

# Kullanıcı arama
results = SearchIndex.search_users(
    query="ahmet",
    limit=10,
    similarity_threshold=0.4
)

# Grup arama
results = SearchIndex.search_groups(
    query="motor",
    limit=5,
    similarity_threshold=0.3
)
```

## Threshold Değerleri

- **0.1-0.2**: Çok gevşek arama (daha fazla sonuç)
- **0.3**: Varsayılan değer (dengeli)
- **0.4-0.5**: Sıkı arama (daha az ama daha doğru sonuç)
- **0.6+**: Çok sıkı arama (sadece çok benzer sonuçlar)

## Sorun Giderme

### Index Senkronizasyon Sorunları

```bash
# Cache'i temizle ve yeniden oluştur
python manage.py sync_search_index --force
```

### Performans Sorunları

1. GIN indexlerinin oluşturulduğundan emin olun
2. `similarity_threshold` değerini artırın
3. `limit` parametresini azaltın

### PostgreSQL Extension Sorunları

```sql
-- Extension'ın yüklendiğini kontrol et
SELECT * FROM pg_extension WHERE extname = 'pg_trgm';

-- Manuel olarak yükle (gerekirse)
CREATE EXTENSION IF NOT EXISTS pg_trgm;
```

## Geçiş Notları

Bu sistem, önceki hash tablosu tabanlı arama sisteminin yerini alır:

- **Eski sistem**: `hash_search.py` (silindi)
- **Yeni sistem**: `pg_trgm_search.py`
- **Avantajlar**: Daha hızlı, daha doğru, PostgreSQL native
- **Geriye uyumluluk**: API endpoint'leri aynı kalır
