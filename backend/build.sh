#!/bin/bash

# Minimal build script for production deployment
# Supabase connection limit sorunları nedeniyle migration'lar devre dışı
set -e

echo "🚀 Starting minimal build process..."

# Create logs directory
mkdir -p logs

# Install dependencies
echo "📦 Installing dependencies..."
pip install -r requirements.txt

# Collect static files only (no database operations)
echo "📁 Collecting static files..."
python manage.py collectstatic --noinput

echo "✅ Minimal build completed successfully!"
echo "⚠️  Database migrations skipped due to Supabase connection limits"
echo "📝 Manual migration required - see MIGRATION_GUIDE.md"