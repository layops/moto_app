import os
from pathlib import Path
try:
    import dj_database_url  # pyright: ignore[reportMissingImports]
except ImportError:
    dj_database_url = None

BASE_DIR = Path(__file__).resolve().parent.parent
BASE_URL = 'https://spiride.onrender.com'

# Google OAuth Configuration
GOOGLE_CLIENT_ID = os.environ.get('GOOGLE_CLIENT_ID')
GOOGLE_CLIENT_SECRET = os.environ.get('GOOGLE_CLIENT_SECRET')
GOOGLE_REDIRECT_URI = os.environ.get('GOOGLE_REDIRECT_URI', f'{BASE_URL}/api/users/auth/callback/')
GOOGLE_CALLBACK_URL = os.environ.get('GOOGLE_CALLBACK_URL', f'{BASE_URL}/api/users/auth/callback/')

# Firebase Cloud Messaging Configuration
FCM_SERVER_KEY = os.environ.get('FCM_SERVER_KEY')
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'
SECRET_KEY = os.environ.get('SECRET_KEY', 'django-insecure-dev-key')
DEBUG = os.environ.get('DEBUG', 'False').lower() == 'true'

ALLOWED_HOSTS = os.environ.get(
    'ALLOWED_HOSTS', 'localhost,127.0.0.1,spiride.onrender.com'
).split(',')

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'django.contrib.postgres',

    # 3rd party
    'rest_framework',
    'rest_framework.authtoken',
    'rest_framework_simplejwt',
    'rest_framework_simplejwt.token_blacklist',
    'corsheaders',
    'drf_yasg',
    'channels',

    # Proje uygulamaları
    'users',
    'bikes',
    'rides',
    'groups',
    'posts',
    'events',
    'media',
    'chat',
    'notifications',
    'gamification',
    'search',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'core_api.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'core_api.wsgi.application'
ASGI_APPLICATION = 'core_api.asgi.application'

# PostgreSQL Database Configuration
DATABASE_URL = os.environ.get('DATABASE_URL')
if DATABASE_URL and dj_database_url:
    # Supabase PostgreSQL için optimize edilmiş ayarlar
    DATABASES = {
        'default': dj_database_url.config(
            default=DATABASE_URL,
            conn_max_age=600,
            conn_health_checks=True,
            ssl_require=True,  # Supabase SSL gerektirir
        )
    }
    print("✅ PostgreSQL database configured")
else:
    print("❌ No DATABASE_URL found")
    raise Exception("DATABASE_URL environment variable is required")

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

LANGUAGE_CODE = 'tr'
TIME_ZONE = 'Europe/Istanbul'
USE_I18N = True
USE_TZ = True

STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

AUTH_USER_MODEL = 'users.CustomUser'

# CORS güvenlik ayarları
CORS_ALLOW_ALL_ORIGINS = DEBUG  # Sadece development'ta True
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    "https://yourdomain.com",  # Production domain'inizi buraya ekleyin
] if not DEBUG else []

# WebSocket için CORS ayarları
CORS_ALLOW_CREDENTIALS = True

# Render.com için WebSocket ayarları
SECURE_SSL_REDIRECT = False  # Render.com'da SSL proxy kullanıldığı için
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')

# Render.com WebSocket desteği için
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
SECURE_SSL_REDIRECT = False
USE_TLS = True
CORS_ALLOW_METHODS = [
    'DELETE',
    'GET',
    'OPTIONS',
    'PATCH',
    'POST',
    'PUT',
]
CORS_ALLOW_HEADERS = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
]

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
        'rest_framework.authentication.TokenAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_RENDERER_CLASSES': [
        'rest_framework.renderers.JSONRenderer',
    ],
    'DEFAULT_PARSER_CLASSES': [
        'rest_framework.parsers.JSONParser',
        'rest_framework.parsers.MultiPartParser',
        'rest_framework.parsers.FormParser',
    ],
    'EXCEPTION_HANDLER': 'core_api.exception_handler.custom_exception_handler'
}

CSRF_COOKIE_HTTPONLY = True
CSRF_USE_SESSIONS = False
CSRF_TRUSTED_ORIGINS = ['http://localhost:3000', 'http://127.0.0.1:3000']
CSRF_COOKIE_SAMESITE = 'Lax'

SWAGGER_SETTINGS = {
    'SECURITY_DEFINITIONS': {
        'Bearer': {
            'type': 'apiKey',
            'name': 'Authorization',
            'in': 'header',
            'description': 'JWT Authorization header using the Bearer scheme. Example: "Authorization: Bearer {token}"'
        }
    },
    'USE_SESSION_AUTH': False,
    'JSON_EDITOR': True,
}

REDOC_SETTINGS = {
    'LAZY_RENDERING': False,
}

CHANNEL_LAYERS = {
    "default": {
        "BACKEND": "channels_redis.core.RedisChannelLayer",
        "CONFIG": {
            "hosts": [os.environ.get('REDIS_URL', 'redis://127.0.0.1:6379')],
        },
    },
}


# Supabase Configuration - REMOVED (using direct Google OAuth instead)
# All Supabase settings have been removed as we now use direct Google OAuth API


# Caching Configuration
# Redis'i geçici olarak devre dışı bırak - bağlantı sorunları nedeniyle
# REDIS_URL = os.environ.get('REDIS_URL')

# Her zaman local memory cache kullan (Redis bağlantı sorunları nedeniyle)
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
        'LOCATION': 'unique-snowflake',
        'OPTIONS': {
            'MAX_ENTRIES': 1000,
            'CULL_FREQUENCY': 3,
        },
        'KEY_PREFIX': 'motoapp',
        'TIMEOUT': 300,  # 5 minutes default
    }
}
print("⚠️ Using local memory cache (Redis disabled due to connection issues)")

# Cache timeout settings
CACHE_TIMEOUTS = {
    'user_profile': 600,  # 10 minutes
    'posts_list': 300,    # 5 minutes
    'groups_list': 600,   # 10 minutes
    'events_list': 300,   # 5 minutes
    'notifications': 60,  # 1 minute
}



# Static files optimization
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

# Media files optimization
FILE_UPLOAD_MAX_MEMORY_SIZE = 5242880  # 5MB
DATA_UPLOAD_MAX_MEMORY_SIZE = 10485760  # 10MB

# Logging Configuration
import os
import logging

# Create logs directory if it doesn't exist
LOGS_DIR = BASE_DIR / 'logs'
if not LOGS_DIR.exists():
    LOGS_DIR.mkdir(exist_ok=True)

# Only configure file logging in production
if not DEBUG:
    LOGGING = {
        'version': 1,
        'disable_existing_loggers': False,
        'formatters': {
            'verbose': {
                'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
                'style': '{',
            },
            'simple': {
                'format': '{levelname} {message}',
                'style': '{',
            },
            'json': {
                'format': '{"level": "%(levelname)s", "time": "%(asctime)s", "module": "%(module)s", "message": "%(message)s"}',
            },
        },
        'handlers': {
            'console': {
                'level': 'INFO',
                'class': 'logging.StreamHandler',
                'formatter': 'verbose',
            },
            'file': {
                'level': 'INFO',
                'class': 'logging.handlers.RotatingFileHandler',
                'filename': LOGS_DIR / 'django.log',
                'maxBytes': 1024*1024*15,  # 15MB
                'backupCount': 10,
                'formatter': 'verbose',
            },
            'error_file': {
                'level': 'ERROR',
                'class': 'logging.handlers.RotatingFileHandler',
                'filename': LOGS_DIR / 'error.log',
                'maxBytes': 1024*1024*15,  # 15MB
                'backupCount': 10,
                'formatter': 'verbose',
            },
        },
        'root': {
            'handlers': ['console', 'file'],
            'level': 'INFO',
        },
        'loggers': {
            'django': {
                'handlers': ['console', 'file'],
                'level': 'INFO',
                'propagate': False,
            },
            'django.request': {
                'handlers': ['error_file'],
                'level': 'ERROR',
                'propagate': False,
            },
            'moto_app': {
                'handlers': ['console', 'file'],
                'level': 'INFO',
                'propagate': False,
            },
        },
    }
else:
    # Development logging - console only
    LOGGING = {
        'version': 1,
        'disable_existing_loggers': False,
        'formatters': {
            'verbose': {
                'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
                'style': '{',
            },
        },
        'handlers': {
            'console': {
                'level': 'DEBUG',
                'class': 'logging.StreamHandler',
                'formatter': 'verbose',
            },
        },
        'root': {
            'handlers': ['console'],
            'level': 'DEBUG',
        },
        'loggers': {
            'django': {
                'handlers': ['console'],
                'level': 'INFO',
                'propagate': False,
            },
            'django.request': {
                'handlers': ['console'],
                'level': 'ERROR',
                'propagate': False,
            },
            'moto_app': {
                'handlers': ['console'],
                'level': 'DEBUG',
                'propagate': False,
            },
        },
    }
    # LOGGING = {
    #     'version': 1,
    #     'disable_existing_loggers': False,
    #     'formatters': {
    #         'verbose': {
    #             'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
    #             'style': '{',
    #         },
    #         'simple': {
    #             'format': '{levelname} {message}',
    #             'style': '{',
    #         },
    #     },
    #     'handlers': {
    #         'file': {
    #             'level': 'INFO',
    #             'class': 'logging.FileHandler',
    #             'filename': 'logs/django.log',
    #             'formatter': 'verbose',
    #         },
    #         'console': {
    #             'level': 'DEBUG',
    #             'class': 'logging.StreamHandler',
    #             'formatter': 'simple',
    #         },
    #     },
    #     'root': {
    #         'handlers': ['console', 'file'],
    #         'level': 'INFO',
    #     },
    #     'loggers': {
    #         'django': {
    #             'handlers': ['console', 'file'],
    #             'level': 'INFO',
    #             'propagate': False,
    #         },
    #     },
    # }

# JWT Settings (geçici olarak devre dışı)
from datetime import timedelta


SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
    'UPDATE_LAST_LOGIN': True,
    'ALGORITHM': 'HS256',
    'SIGNING_KEY': SECRET_KEY,
    'VERIFYING_KEY': None,
    'AUDIENCE': None,
    'ISSUER': None,
    'JWK_URL': None,
    'LEEWAY': 0,
    'AUTH_HEADER_TYPES': ('Bearer',),
    'AUTH_HEADER_NAME': 'HTTP_AUTHORIZATION',
    'USER_ID_FIELD': 'id',
    'USER_ID_CLAIM': 'user_id',
    'USER_AUTHENTICATION_RULE': 'rest_framework_simplejwt.authentication.default_user_authentication_rule',
    'AUTH_TOKEN_CLASSES': ('rest_framework_simplejwt.tokens.AccessToken',),
    'TOKEN_TYPE_CLAIM': 'token_type',
    'JTI_CLAIM': 'jti',
    'SLIDING_TOKEN_REFRESH_EXP_CLAIM': 'refresh_exp',
    'SLIDING_TOKEN_LIFETIME': timedelta(minutes=5),
    'SLIDING_TOKEN_REFRESH_LIFETIME': timedelta(days=1),
    'TOKEN_OBTAIN_SERIALIZER': 'rest_framework_simplejwt.serializers.TokenObtainPairSerializer',
    'TOKEN_REFRESH_SERIALIZER': 'rest_framework_simplejwt.serializers.TokenRefreshSerializer',
    'TOKEN_VERIFY_SERIALIZER': 'rest_framework_simplejwt.serializers.TokenVerifySerializer',
    'TOKEN_BLACKLIST_SERIALIZER': 'rest_framework_simplejwt.serializers.TokenBlacklistSerializer',
}