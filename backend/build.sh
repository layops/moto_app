#!/bin/bash

# Ultra minimal build script for production deployment
# Supabase connection limit sorunları nedeniyle tüm DB işlemleri devre dışı
set -e

echo "🚀 Starting ultra minimal build process..."

# Create logs directory
mkdir -p logs

# Install dependencies
echo "📦 Installing dependencies..."
pip install -r requirements.txt

# Skip collectstatic to avoid database connection
echo "⚠️  Skipping collectstatic due to Supabase connection limits"
echo "📁 Static files will be collected at runtime if needed"

echo "✅ Ultra minimal build completed successfully!"
echo "⚠️  All database operations skipped due to Supabase connection limits"
echo "📝 Manual migration required - see MIGRATION_GUIDE.md"
echo "🔧 Static files will be handled by WhiteNoise at runtime"