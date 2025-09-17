# 🚫 OFFLINE MODE - Supabase Bağlantı Sorunları Çözümü

Bu doküman Supabase bağlantı sorunları nedeniyle uygulamanın offline mode'da nasıl çalıştırılacağını açıklar.

## 🚨 Sorun

Supabase PostgreSQL veritabanında şu sorunlar yaşanıyor:
- `FATAL: Max client connections reached`
- `Connection refused`
- `Connection timeout`

Bu sorunlar deployment sırasında Django'nun veritabanına bağlanmasını engelliyor.

## 🔧 Çözüm: OFFLINE MODE

Offline mode'da uygulama SQLite veritabanı kullanarak çalışır ve Supabase'e hiç bağlanmaz.

### Aktifleştirme

```bash
# Environment variable ile
export OFFLINE_MODE=true

# Veya Render.com environment variables'da
OFFLINE_MODE=true
```

## 📋 Offline Mode Özellikleri

### ✅ Çalışan Özellikler
- ✅ Django Admin Panel
- ✅ REST API endpoints
- ✅ Static files serving
- ✅ User authentication
- ✅ Basic CRUD operations
- ✅ File uploads
- ✅ WebSocket connections

### ⚠️ Sınırlamalar
- ⚠️ Veriler SQLite'da saklanır (geçici)
- ⚠️ Multi-instance scaling yok
- ⚠️ Veri kalıcılığı sınırlı
- ⚠️ Production için uygun değil

## 🚀 Deployment Süreci

### 1. Build Phase
```bash
# Build script otomatik olarak offline mode'u aktif eder
./build.sh
```

### 2. Runtime Phase
```bash
# Startup script otomatik olarak:
# - SQLite migration'ları çalıştırır
# - Superuser oluşturur
# - Static files collect eder
# - Uvicorn server başlatır
python start_server.py
```

## 📊 Veritabanı Yapısı

Offline mode'da SQLite veritabanı şu dosyalarda saklanır:
- `db_offline.sqlite3` - Offline mode için
- `db_fallback.sqlite3` - Fallback için

## 🔄 Supabase'e Geçiş

Supabase sorunları çözüldüğünde:

### 1. Environment Variable'ı Kaldır
```bash
unset OFFLINE_MODE
# veya Render.com'da OFFLINE_MODE=false
```

### 2. Migration'ları Çalıştır
```bash
python manage.py migrate
```

### 3. Veri Transferi (Gerekirse)
SQLite'dan Supabase'e veri transferi için:
```python
# Django shell'de
python manage.py shell
>>> # Veri transfer script'i çalıştır
```

## 🛠️ Troubleshooting

### SQLite Permission Hatası
```bash
chmod 664 db_offline.sqlite3
chmod 664 db_fallback.sqlite3
```

### Migration Hatası
```bash
# SQLite migration'larını sıfırla
rm db_offline.sqlite3
python manage.py migrate
```

### Static Files Hatası
```bash
# Static files'ı manuel collect et
python manage.py collectstatic --noinput
```

## 📈 Performance

### SQLite Avantajları
- ✅ Hızlı başlangıç
- ✅ Düşük memory kullanımı
- ✅ Bağlantı limiti yok
- ✅ Basit deployment

### SQLite Dezavantajları
- ❌ Concurrent write limitleri
- ❌ Network erişimi yok
- ❌ Scaling zorluğu
- ❌ Backup karmaşıklığı

## 🔍 Monitoring

Offline mode'da monitoring için:

```python
# Django shell'de veritabanı durumunu kontrol et
python manage.py shell
>>> from django.db import connection
>>> connection.vendor  # 'sqlite' olmalı
>>> connection.settings_dict['NAME']  # SQLite dosya yolu
```

## 📞 Destek

Offline mode ile ilgili sorunlar için:
1. Log dosyalarını kontrol edin
2. SQLite dosya izinlerini kontrol edin
3. Environment variables'ı kontrol edin
4. Bu README'yi takip edin

## 🎯 Sonuç

Offline mode Supabase bağlantı sorunlarını geçici olarak çözer ve uygulamanın çalışmasını sağlar. Ancak production ortamında Supabase'e geçiş yapılması önerilir.
