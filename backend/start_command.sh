#!/bin/bash

# Basit start command - superuser oluşturma kaldırıldı
python manage.py collectstatic --noinput && uvicorn core_api.asgi:application --host 0.0.0.0 --port $PORT --workers 2

