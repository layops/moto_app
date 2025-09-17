#!/bin/bash

# Supabase optimized build script for production deployment
set -e

echo "🚀 Starting Supabase optimized build process..."

# Create logs directory
mkdir -p logs

# Install dependencies
echo "📦 Installing dependencies..."
pip install -r requirements.txt

# Test Supabase connection before proceeding
echo "🔍 Testing Supabase connection..."
if python -c "
import os
import psycopg2
from urllib.parse import urlparse

DATABASE_URL = os.environ.get('DATABASE_URL')
if DATABASE_URL:
    try:
        # Parse connection string
        result = urlparse(DATABASE_URL)
        conn = psycopg2.connect(
            host=result.hostname,
            port=result.port,
            database=result.path[1:],
            user=result.username,
            password=result.password,
            connect_timeout=5,
            sslmode='require'
        )
        conn.close()
        print('✅ Supabase connection test successful')
        exit(0)
    except Exception as e:
        print(f'❌ Supabase connection test failed: {e}')
        exit(1)
else:
    print('❌ No DATABASE_URL found')
    exit(1)
"; then
    echo "✅ Supabase connection verified"
else
    echo "❌ Supabase connection failed - check your DATABASE_URL"
    echo "🔧 Please verify your Supabase project is active and accessible"
    exit 1
fi

echo "✅ Supabase optimized build completed successfully!"
echo "🗄️  Ready to use Supabase PostgreSQL"
echo "📁 Static files will be collected at runtime"