# Render.com Deployment Guide

## Environment Variables

Render.com'da aşağıdaki environment variables'ları ayarlayın:

### Required Variables:
- `SECRET_KEY`: Django secret key
- `DEBUG`: False
- `ALLOWED_HOSTS`: your-app-name.onrender.com,localhost,127.0.0.1

### Database:
- `DATABASE_URL`: Render.com otomatik olarak PostgreSQL service için sağlar

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
- **Start Command**: `python manage.py collectstatic --noinput && python manage.py shell -c "from django.contrib.auth import get_user_model; User=get_user_model(); User.objects.create_superuser('superuser','superuser@spiride.com','326598') if not User.objects.filter(username='superuser').exists() else print('Superuser already exists')" && uvicorn core_api.asgi:application --host 0.0.0.0 --port $PORT --workers 2`

## Services Needed

1. **Web Service**: Django backend
2. **PostgreSQL Database**: Database service
3. **Redis**: Cache ve WebSocket için

## Troubleshooting

### Database Connection Issues:
- DATABASE_URL'ın doğru olduğundan emin olun
- PostgreSQL service'in çalıştığından emin olun
- SSL bağlantıları Render.com'da otomatik olarak yönetilir

### Static Files:
- collectstatic komutu build sırasında çalışır
- WhiteNoise static file serving kullanır

### Performance:
- Connection pooling aktif
- Redis caching aktif
- Gunicorn 2 worker ile çalışır
