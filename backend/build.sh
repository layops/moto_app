#!/usr/bin/env bash
# Render.com build script

echo "Starting build process..."

# Python dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Django setup
echo "Collecting static files..."
python manage.py collectstatic --noinput

echo "Running migrations..."
python manage.py migrate

echo "Build completed successfully!"
