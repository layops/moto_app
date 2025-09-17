#!/bin/bash

# Build script for production deployment
set -e

echo "🚀 Starting build process..."

# Create logs directory
mkdir -p logs

# Install dependencies
echo "📦 Installing dependencies..."
pip install -r requirements.txt

# Run migrations
echo "🗄️ Running database migrations..."
python manage.py makemigrations --noinput
python manage.py migrate --noinput

# Collect static files
echo "📁 Collecting static files..."
python manage.py collectstatic --noinput

# Create superuser if not exists
echo "👤 Creating superuser..."
python manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='superuser').exists():
    User.objects.create_superuser('superuser', 'superuser@spiride.com', '326598')
    print('Superuser created successfully')
else:
    print('Superuser already exists')
"

# Initialize notification preferences for existing users
echo "🔔 Initializing notification preferences..."
python manage.py shell -c "
from django.contrib.auth import get_user_model
from notifications.models import NotificationPreferences
User = get_user_model()
users_without_prefs = User.objects.filter(notification_preferences__isnull=True)
for user in users_without_prefs:
    NotificationPreferences.objects.create(user=user)
    print(f'Created notification preferences for {user.username}')
print(f'Initialized notification preferences for {users_without_prefs.count()} users')
"

# Create achievements
echo "🏆 Creating achievements..."
python manage.py create_achievements --verbosity=2

# Run health check
echo "🏥 Running health check..."
python manage.py shell -c "
from core_api.health_check import health_check
from django.test import RequestFactory
factory = RequestFactory()
request = factory.get('/health/')
response = health_check(request)
print(f'Health check status: {response.status_code}')
"

echo "✅ Build completed successfully!"