# Event Management Commands

## cleanup_expired_events

Süresi geçmiş event'leri temizler.

### Kullanım:

```bash
# Test modu - sadece hangi event'lerin silineceğini göster
python manage.py cleanup_expired_events --dry-run

# Varsayılan (7 gün sonra sil)
python manage.py cleanup_expired_events

# Özel gün sayısı (3 gün sonra sil)
python manage.py cleanup_expired_events --days-after 3

# Test modu ile özel gün sayısı
python manage.py cleanup_expired_events --dry-run --days-after 1
```

### Parametreler:

- `--dry-run`: Sadece hangi event'lerin silineceğini göster, gerçekten silme
- `--days-after`: Event bitiş tarihinden kaç gün sonra silinsin (varsayılan: 7)

### Örnek Çıktı:

```
Süresi geçmiş event'ler temizleniyor...
Şu anki zaman: 2025-01-15 10:30:00+00:00
Silme tarihi: 2025-01-08 10:30:00+00:00 (Event bitiş tarihi + 7 gün)
Silinecek event sayısı: 2
- ID: 4, Başlık: Eski Etkinlik 1, Başlangıç: 2025-01-05 14:00, Bitiş: 2025-01-05 16:00, Organizatör: user1
- ID: 5, Başlık: Eski Etkinlik 2, Başlangıç: 2025-01-06 10:00, Bitiş: Yok, Organizatör: user2

2 adet süresi geçmiş event başarıyla silindi.
Kalan event sayısı: 3
```

### Otomatik Çalışma:

Render.com'da her deploy'da otomatik olarak çalışır:
- Event bitiş tarihinden 7 gün sonra silinir
- Log'larda hangi event'lerin silindiği görülür
- Hata durumunda deploy durmaz, sadece log'a yazılır
