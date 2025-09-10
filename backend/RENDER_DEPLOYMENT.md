# Render.com Deployment Guide

## Environment Variables

Render.com'da aşağıdaki environment variables'ları ayarlayın:

### Required Variables:
- `SECRET_KEY`: Django secret key
- `DEBUG`: False
- `ALLOWED_HOSTS`: your-app-name.onrender.com,localhost,127.0.0.1

### Database:
- `DATABASE_URL`: Supabase PostgreSQL connection string (postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres)

### Redis:
- `REDIS_URL`: Render.com Redis service URL'i

### Supabase:
- `SUPABASE_URL`: https://your-project.supabase.co
- `SUPABASE_SERVICE_KEY`: Supabase service key
- `SUPABASE_BUCKET`: profile_pictures
- `SUPABASE_COVER_BUCKET`: cover_pictures
- `SUPABASE_EVENTS_BUCKET`: events_pictures
- `SUPABASE_GROUPS_BUCKET`: groups_profile_pictures
- `SUPABASE_POSTS_BUCKET`: group_posts_images
- `SUPABASE_PROJECT_ID`: your-project-id

## Build Settings

- **Build Command**: `pip install -r requirements.txt && python manage.py migrate --noinput`
- **Start Command**: `python manage.py collectstatic --noinput && python manage.py create_achievements --verbosity=2 && python manage.py shell -c "from django.contrib.auth import get_user_model; User=get_user_model(); User.objects.create_superuser('superuser','superuser@spiride.com','326598') if not User.objects.filter(username='superuser').exists() else print('Superuser already exists')" && uvicorn core_api.asgi:application --host 0.0.0.0 --port $PORT --workers 2`

## Services Needed

1. **Web Service**: Django backend
2. **Supabase**: PostgreSQL Database + Storage + Realtime
3. **Redis**: Cache ve WebSocket için (opsiyonel - Supabase Realtime kullanılabilir)

## Troubleshooting

### Database Connection Issues:
- DATABASE_URL'ın doğru olduğundan emin olun (Supabase connection string)
- Supabase PostgreSQL service'in çalıştığından emin olun
- SSL bağlantıları Supabase'de otomatik olarak yönetilir
- Connection pooling için Supabase dashboard'unda ayarları kontrol edin

### Static Files:
- collectstatic komutu build sırasında çalışır
- WhiteNoise static file serving kullanır

### Performance:
- Connection pooling aktif
- Redis caching aktif
- Gunicorn 2 worker ile çalışır
