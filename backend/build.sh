#!/bin/bash

# Offline mode build script for production deployment
# Supabase bağlantı sorunları nedeniyle offline mode kullanılıyor
set -e

echo "🚀 Starting OFFLINE MODE build process..."

# Create logs directory
mkdir -p logs

# Install dependencies
echo "📦 Installing dependencies..."
pip install -r requirements.txt

# Set offline mode environment variable
export OFFLINE_MODE=true
echo "⚠️  OFFLINE MODE activated - will use SQLite instead of Supabase"

echo "✅ OFFLINE MODE build completed successfully!"
echo "🗄️  Will use SQLite database instead of Supabase"
echo "📁 Static files will be collected at runtime"
echo "🔧 All database operations will use local SQLite"