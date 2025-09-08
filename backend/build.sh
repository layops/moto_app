#!/usr/bin/env bash
# Render.com build script

echo "Starting build process..."

# Python dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Django setup
python manage.py collectstatic --noinput
python manage.py migrate

echo "Build completed successfully!"
