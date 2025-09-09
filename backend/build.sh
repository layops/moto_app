#!/usr/bin/env bash
# Render.com build script

echo "Starting build process..."

# Python dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Django setup
echo "Running migrations..."
python manage.py migrate --noinput

echo "Creating achievements..."
python manage.py create_achievements

echo "Build completed successfully!"
