#!/bin/bash

# Supabase optimized build script for production deployment
set -e

echo "🚀 Starting Supabase optimized build process..."

# Create logs directory
mkdir -p logs

# Install dependencies
echo "📦 Installing dependencies..."
pip install -r requirements.txt

# Skip connection test - migrations will handle connection
echo "✅ Skipping connection test - will connect during migrations"

# Run migrations
echo "🗄️ Running migrations..."
python manage.py migrate --noinput

echo "✅ Supabase optimized build completed successfully!"
echo "🗄️  Ready to use Supabase PostgreSQL"
echo "📁 Static files will be collected at runtime"