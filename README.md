# 🏍️ MotoApp - Motosiklet Topluluğu Uygulaması

Modern motosiklet topluluğu için geliştirilmiş kapsamlı bir mobil ve web uygulaması.

## 🚀 Özellikler

### 📱 Frontend (Flutter)
- **Modern UI/UX**: Material Design 3 ile tasarlanmış kullanıcı dostu arayüz
- **Dark/Light Theme**: Kullanıcı tercihine göre tema değiştirme
- **Responsive Design**: Tüm ekran boyutlarına uyumlu tasarım
- **Real-time Chat**: WebSocket tabanlı anlık mesajlaşma
- **Harita Entegrasyonu**: Motosiklet rotaları ve konum paylaşımı
- **Grup Yönetimi**: Motosiklet grupları oluşturma ve yönetme
- **Etkinlik Takibi**: Motosiklet etkinlikleri düzenleme ve katılım
- **Profil Yönetimi**: Detaylı kullanıcı profilleri
- **Bildirim Sistemi**: Push notification desteği

### 🔧 Backend (Django)
- **RESTful API**: Django REST Framework ile güçlü API
- **Real-time**: WebSocket desteği (Django Channels)
- **Authentication**: Token tabanlı kimlik doğrulama
- **File Storage**: Supabase ile medya dosyası yönetimi
- **Caching**: Redis tabanlı performans optimizasyonu
- **Database**: PostgreSQL/SQLite desteği
- **API Documentation**: Swagger/OpenAPI dokümantasyonu

## 🛠️ Teknoloji Stack

### Frontend
- **Flutter** 3.16+
- **Dart** 3.0+
- **Provider/Riverpod** - State Management
- **Dio** - HTTP Client
- **Supabase** - Backend as a Service
- **WebSocket** - Real-time Communication
- **Google Fonts** - Typography
- **Flutter ScreenUtil** - Responsive Design

### Backend
- **Django** 5.2+
- **Django REST Framework** - API Framework
- **Django Channels** - WebSocket Support
- **PostgreSQL** - Primary Database
- **Redis** - Caching & Session Storage
- **Supabase** - File Storage
- **Gunicorn** - WSGI Server
- **WhiteNoise** - Static File Serving

## 📦 Kurulum

### Gereksinimler
- Python 3.11+
- Flutter 3.16+
- PostgreSQL 14+
- Redis 6+

### Backend Kurulumu

1. **Repository'yi klonlayın**
```bash
git clone <repository-url>
cd moto_app/backend
```

2. **Virtual environment oluşturun**
```bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
# veya
venv\Scripts\activate  # Windows
```

3. **Bağımlılıkları yükleyin**
```bash
pip install -r requirements.txt
```

4. **Environment variables ayarlayın**
```bash
cp env.example .env
# .env dosyasını düzenleyin
```

5. **Veritabanı migrasyonlarını çalıştırın**
```bash
python manage.py migrate
```

6. **Superuser oluşturun**
```bash
python manage.py createsuperuser
```

7. **Sunucuyu başlatın**
```bash
python manage.py runserver
```

### Frontend Kurulumu

1. **Frontend dizinine gidin**
```bash
cd ../frontend
```

2. **Flutter bağımlılıklarını yükleyin**
```bash
flutter pub get
```

3. **Uygulamayı çalıştırın**
```bash
flutter run
```

## 🔧 Konfigürasyon

### Environment Variables

Backend için gerekli environment variables:

```env
# Django Settings
SECRET_KEY=your-secret-key-here
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/motoapp

# Redis
REDIS_URL=redis://127.0.0.1:6379

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your-service-key-here
```

### Supabase Kurulumu

1. [Supabase](https://supabase.com) hesabı oluşturun
2. Yeni proje oluşturun
3. Storage bucket'ları oluşturun:
   - `profile_pictures`
   - `cover_pictures`
   - `events_pictures`
   - `groups_profile_pictures`
   - `group_posts_images`

## 📱 API Dokümantasyonu

API dokümantasyonuna erişim:
- **Swagger UI**: `http://localhost:8000/swagger/`
- **ReDoc**: `http://localhost:8000/redoc/`

## 🏗️ Proje Yapısı

```
moto_app/
├── backend/
│   ├── core_api/          # Ana Django projesi
│   ├── users/             # Kullanıcı yönetimi
│   ├── posts/             # Gönderi sistemi
│   ├── groups/            # Grup yönetimi
│   ├── events/            # Etkinlik sistemi
│   ├── chat/              # Mesajlaşma
│   ├── notifications/     # Bildirim sistemi
│   └── media/             # Medya yönetimi
└── frontend/
    ├── lib/
    │   ├── core/          # Temel yapılar
    │   ├── services/      # API servisleri
    │   ├── views/         # Sayfalar
    │   ├── widgets/       # UI bileşenleri
    │   └── models/        # Veri modelleri
    └── assets/            # Statik dosyalar
```

## 🚀 Deployment

### Backend (Render/Heroku)

1. **Procfile** zaten mevcut
2. **Environment variables** ayarlayın
3. **Git push** yapın

### Frontend (Firebase/App Store)

1. **Build** oluşturun
```bash
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

2. **Deploy** edin

## 🤝 Katkıda Bulunma

1. Fork yapın
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit yapın (`git commit -m 'Add amazing feature'`)
4. Push yapın (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır.

## 📞 İletişim

- **Email**: [your-email@example.com]
- **LinkedIn**: [your-linkedin]
- **GitHub**: [your-github]

## 🙏 Teşekkürler

- Flutter ekibine
- Django ekibine
- Supabase ekibine
- Tüm açık kaynak katkıda bulunanlara

---

**Not**: Bu proje geliştirme aşamasındadır. Production kullanımı için ek güvenlik önlemleri alınması önerilir.
