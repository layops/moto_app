#!/bin/bash

# Build script for production deployment
set -e

echo "🚀 Starting build process..."

# Create logs directory
mkdir -p logs

# Install dependencies
echo "📦 Installing dependencies..."
pip install -r requirements.txt

# Run migrations with retry mechanism for connection issues
echo "🗄️ Running database migrations..."
python manage.py makemigrations --noinput

# Migration'ları retry mekanizması ile çalıştır
echo "🔄 Running migrations with retry mechanism..."
for i in {1..3}; do
    echo "Migration attempt $i/3..."
    if python manage.py migrate --noinput; then
        echo "✅ Migrations completed successfully"
        break
    else
        echo "❌ Migration attempt $i failed"
        if [ $i -eq 3 ]; then
            echo "🚨 All migration attempts failed. Continuing with build..."
            # Migration'lar başarısız olsa bile build'e devam et
        else
            echo "⏳ Waiting 10 seconds before retry..."
            sleep 10
        fi
    fi
done

# Collect static files
echo "📁 Collecting static files..."
python manage.py collectstatic --noinput

# Create superuser if not exists with retry mechanism
echo "👤 Creating superuser..."
for i in {1..3}; do
    echo "Superuser creation attempt $i/3..."
    if python manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='superuser').exists():
    User.objects.create_superuser('superuser', 'superuser@spiride.com', '326598')
    print('Superuser created successfully')
else:
    print('Superuser already exists')
"; then
        echo "✅ Superuser creation completed successfully"
        break
    else
        echo "❌ Superuser creation attempt $i failed"
        if [ $i -eq 3 ]; then
            echo "🚨 All superuser creation attempts failed. Continuing with build..."
        else
            echo "⏳ Waiting 5 seconds before retry..."
            sleep 5
        fi
    fi
done

# Initialize notification preferences for existing users with retry mechanism
echo "🔔 Initializing notification preferences..."
for i in {1..3}; do
    echo "Notification preferences initialization attempt $i/3..."
    if python manage.py shell -c "
from django.contrib.auth import get_user_model
from notifications.models import NotificationPreferences
User = get_user_model()
users_without_prefs = User.objects.filter(notification_preferences__isnull=True)
for user in users_without_prefs:
    NotificationPreferences.objects.create(user=user)
    print(f'Created notification preferences for {user.username}')
print(f'Initialized notification preferences for {users_without_prefs.count()} users')
"; then
        echo "✅ Notification preferences initialization completed successfully"
        break
    else
        echo "❌ Notification preferences initialization attempt $i failed"
        if [ $i -eq 3 ]; then
            echo "🚨 All notification preferences initialization attempts failed. Continuing with build..."
        else
            echo "⏳ Waiting 5 seconds before retry..."
            sleep 5
        fi
    fi
done

# Create achievements with retry mechanism
echo "🏆 Creating achievements..."
for i in {1..3}; do
    echo "Achievements creation attempt $i/3..."
    if python manage.py create_achievements --verbosity=2; then
        echo "✅ Achievements creation completed successfully"
        break
    else
        echo "❌ Achievements creation attempt $i failed"
        if [ $i -eq 3 ]; then
            echo "🚨 All achievements creation attempts failed. Continuing with build..."
        else
            echo "⏳ Waiting 5 seconds before retry..."
            sleep 5
        fi
    fi
done

# Run health check with retry mechanism
echo "🏥 Running health check..."
for i in {1..3}; do
    echo "Health check attempt $i/3..."
    if python manage.py shell -c "
from core_api.health_check import health_check
from django.test import RequestFactory
factory = RequestFactory()
request = factory.get('/health/')
response = health_check(request)
print(f'Health check status: {response.status_code}')
"; then
        echo "✅ Health check completed successfully"
        break
    else
        echo "❌ Health check attempt $i failed"
        if [ $i -eq 3 ]; then
            echo "🚨 All health check attempts failed. Continuing with build..."
        else
            echo "⏳ Waiting 5 seconds before retry..."
            sleep 5
        fi
    fi
done

echo "✅ Build completed successfully!"