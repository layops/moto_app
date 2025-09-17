# 🗄️ Manuel Migration Rehberi

Bu rehber Supabase bağlantı limitleri nedeniyle otomatik migration'ların çalışmadığı durumlarda manuel olarak migration'ları nasıl çalıştıracağınızı açıklar.

## 🚨 Önemli Not

Supabase'in ücretsiz planında maksimum bağlantı limiti vardır. Bu nedenle deployment sırasında migration'lar otomatik olarak çalıştırılmaz.

## 📋 Manuel Migration Adımları

### 1. Supabase Dashboard'a Giriş
- Supabase dashboard'unuza giriş yapın
- Projenizi seçin
- "SQL Editor" sekmesine gidin

### 2. Migration Dosyalarını Kontrol Et
Aşağıdaki migration dosyalarını kontrol edin:

```bash
# Migration dosyalarını listele
ls -la backend/*/migrations/0*.py
```

### 3. Manuel Migration Komutları

#### Chat App Migration
```sql
-- HiddenConversation tablosu oluştur
CREATE TABLE IF NOT EXISTS "chat_hiddenconversation" (
    "id" bigserial NOT NULL PRIMARY KEY,
    "user_id" bigint NOT NULL,
    "conversation_id" bigint NOT NULL,
    "hidden_at" timestamp with time zone NOT NULL,
    FOREIGN KEY ("user_id") REFERENCES "users_customuser" ("id") DEFERRABLE INITIALLY DEFERRED,
    FOREIGN KEY ("conversation_id") REFERENCES "chat_conversation" ("id") DEFERRABLE INITIALLY DEFERRED
);
```

#### Notifications App Migration
```sql
-- NotificationPreferences tablosu oluştur
CREATE TABLE IF NOT EXISTS "notifications_notificationpreferences" (
    "id" bigserial NOT NULL PRIMARY KEY,
    "user_id" bigint NOT NULL UNIQUE,
    "email_notifications" boolean NOT NULL DEFAULT true,
    "push_notifications" boolean NOT NULL DEFAULT true,
    "ride_notifications" boolean NOT NULL DEFAULT true,
    "group_notifications" boolean NOT NULL DEFAULT true,
    "event_notifications" boolean NOT NULL DEFAULT true,
    "created_at" timestamp with time zone NOT NULL,
    "updated_at" timestamp with time zone NOT NULL,
    FOREIGN KEY ("user_id") REFERENCES "users_customuser" ("id") DEFERRABLE INITIALLY DEFERRED
);

-- Notification tablosunu güncelle
ALTER TABLE "notifications_notification" 
ALTER COLUMN "notification_type" TYPE varchar(50) USING "notification_type"::varchar(50);
```

#### Posts App Migration
```sql
-- PostLike unique constraint'ini kaldır
ALTER TABLE "posts_postlike" DROP CONSTRAINT IF EXISTS "unique_post_user_like";

-- Yeni unique constraint ekle
ALTER TABLE "posts_postlike" ADD CONSTRAINT "posts_postlike_post_id_user_id_unique" 
UNIQUE ("post_id", "user_id");
```

#### Users App Migration
```sql
-- CustomUser tablosuna yeni alanlar ekle
ALTER TABLE "users_customuser" 
ADD COLUMN IF NOT EXISTS "email_verification_token" varchar(255) NULL,
ADD COLUMN IF NOT EXISTS "email_verified" boolean NOT NULL DEFAULT false;

-- Email alanını güncelle
ALTER TABLE "users_customuser" 
ALTER COLUMN "email" TYPE varchar(254) USING "email"::varchar(254);
```

#### Media App Migration
```sql
-- Media tablosunu güncelle
ALTER TABLE "media_media" 
ALTER COLUMN "group_id" TYPE bigint USING "group_id"::bigint,
ALTER COLUMN "uploaded_by_id" TYPE bigint USING "uploaded_by_id"::bigint;
```

### 4. Superuser Oluşturma

Migration'lar tamamlandıktan sonra superuser oluşturun:

```sql
-- Superuser oluştur (eğer yoksa)
INSERT INTO "users_customuser" (
    "password", "is_superuser", "username", "first_name", "last_name", 
    "email", "is_staff", "is_active", "date_joined", "email_verified"
) VALUES (
    'pbkdf2_sha256$600000$...', -- Django'nun hash'lediği şifre
    true, 'superuser', '', '', 'superuser@spiride.com', true, true, NOW(), true
) ON CONFLICT (username) DO NOTHING;
```

### 5. Notification Preferences Oluşturma

```sql
-- Mevcut kullanıcılar için notification preferences oluştur
INSERT INTO "notifications_notificationpreferences" (
    "user_id", "email_notifications", "push_notifications", 
    "ride_notifications", "group_notifications", "event_notifications",
    "created_at", "updated_at"
)
SELECT 
    u.id, true, true, true, true, true, NOW(), NOW()
FROM "users_customuser" u
LEFT JOIN "notifications_notificationpreferences" np ON u.id = np.user_id
WHERE np.user_id IS NULL;
```

### 6. Achievements Oluşturma

```sql
-- Gamification achievements oluştur
INSERT INTO "gamification_achievement" (
    "name", "description", "icon", "points", "category", "is_active", "created_at", "updated_at"
) VALUES 
('İlk Sürüş', 'İlk sürüşünüzü tamamladınız!', '🚗', 10, 'ride', true, NOW(), NOW()),
('Grup Kurucusu', 'İlk grubunuzu kurdunuz!', '👥', 20, 'group', true, NOW(), NOW()),
('Sosyal Kelebek', '10 farklı kişiyle sürüş yaptınız!', '🦋', 50, 'social', true, NOW(), NOW()),
('Uzun Yolcu', '100km sürüş yaptınız!', '🛣️', 100, 'distance', true, NOW(), NOW()),
('Etkinlik Katılımcısı', 'İlk etkinliğinize katıldınız!', '🎉', 25, 'event', true, NOW(), NOW())
ON CONFLICT (name) DO NOTHING;
```

## 🔍 Migration Durumunu Kontrol Etme

Migration'ların başarılı olup olmadığını kontrol etmek için:

```sql
-- Tabloları kontrol et
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE '%chat%' OR table_name LIKE '%notification%' 
OR table_name LIKE '%post%' OR table_name LIKE '%user%' 
OR table_name LIKE '%media%' OR table_name LIKE '%gamification%';

-- Constraint'leri kontrol et
SELECT constraint_name, table_name, constraint_type 
FROM information_schema.table_constraints 
WHERE table_schema = 'public';
```

## ⚠️ Önemli Uyarılar

1. **Backup Alın**: Migration'ları çalıştırmadan önce veritabanınızın yedeğini alın
2. **Sıralı Çalıştırın**: Migration'ları sırayla çalıştırın
3. **Hata Kontrolü**: Her migration'dan sonra hata olup olmadığını kontrol edin
4. **Test Edin**: Migration'lar tamamlandıktan sonra uygulamayı test edin

## 🆘 Sorun Giderme

### Bağlantı Hatası
- Supabase dashboard'da aktif bağlantıları kontrol edin
- Bağlantı limitini aşmamak için migration'ları tek tek çalıştırın

### Constraint Hatası
- Önce eski constraint'leri kaldırın
- Sonra yeni constraint'leri ekleyin

### Tablo Bulunamadı Hatası
- Tabloların doğru sırayla oluşturulduğundan emin olun
- Foreign key'lerin referans ettiği tabloların mevcut olduğunu kontrol edin

## 📞 Destek

Migration'larla ilgili sorun yaşarsanız:
1. Supabase dashboard'da SQL Editor'ü kullanın
2. Hata mesajlarını dikkatli okuyun
3. Bu rehberi adım adım takip edin
