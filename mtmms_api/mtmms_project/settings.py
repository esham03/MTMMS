"""
MTMMS Django Settings
Replaces Laravel's config/ — same MySQL database, same API structure
"""

import os
from pathlib import Path
from datetime import timedelta
from dotenv import load_dotenv

# Load .env file and dynamic runtime environment
BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / '.env')
load_dotenv(BASE_DIR.parent / '.mtmms-runtime.env')

SECRET_KEY = os.getenv('SECRET_KEY', 'mtmms-insecure-dev-key')
DEBUG = os.getenv('DEBUG', 'True') == 'True'

# Dynamic LAN Host Configuration
raw_allowed_hosts = os.getenv('ALLOWED_HOSTS', '*')
if raw_allowed_hosts == '*' or DEBUG:
    ALLOWED_HOSTS = ['*']
else:
    ALLOWED_HOSTS = [h.strip() for h in raw_allowed_hosts.split(',') if h.strip()]
    server_ip = os.getenv('MTMMS_SERVER_IP')
    if server_ip and server_ip not in ALLOWED_HOSTS:
        ALLOWED_HOSTS.append(server_ip)
    for default_h in ['localhost', '127.0.0.1', '0.0.0.0']:
        if default_h not in ALLOWED_HOSTS:
            ALLOWED_HOSTS.append(default_h)

INSTALLED_APPS = [
    # 'django.contrib.admin',  # Disabled to avoid FK conflict with existing users table
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    # Third-party
    'rest_framework',
    'rest_framework_simplejwt',
    'corsheaders',
    # MTMMS apps
    'apps.auth_app',
    'apps.locations',
    'apps.owners',
    'apps.operators',
    'apps.towers',
    'apps.rent_payments',
    'apps.dashboard',
    'apps.reports',
    'apps.users',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',  # Must be first
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'mtmms_project.urls'

# Suppress auth.E002 — we use a custom User model without admin
SILENCED_SYSTEM_CHECKS = ['auth.E002']

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

WSGI_APPLICATION = 'mtmms_project.wsgi.application'

# ─────────────────────────────────────────
# Database — Supports DATABASE_URL (Cloud) or Local MySQL
# ─────────────────────────────────────────
if os.getenv('DATABASE_URL'):
    import dj_database_url
    DATABASES = {
        'default': dj_database_url.config(
            default=os.getenv('DATABASE_URL'),
            conn_max_age=600,
        )
    }
else:
    DATABASES = {
        'default': {
            'ENGINE':   'django.db.backends.mysql',
            'NAME':     os.getenv('DB_NAME', 'mtmms'),
            'USER':     os.getenv('DB_USER', 'root'),
            'PASSWORD': os.getenv('DB_PASSWORD', ''),
            'HOST':     os.getenv('DB_HOST', '127.0.0.1'),
            'PORT':     os.getenv('DB_PORT', '3306'),
            'OPTIONS': {
                'charset': 'utf8mb4',
            },
        }
    }

# ─────────────────────────────────────────
# Custom User Model
# ─────────────────────────────────────────
AUTH_USER_MODEL = 'auth_app.User'

# ─────────────────────────────────────────
# Password Hashers
# Supports existing Laravel bcrypt hashes ($2y$) AND new Django hashes
# ─────────────────────────────────────────
PASSWORD_HASHERS = [
    'django.contrib.auth.hashers.PBKDF2PasswordHasher',  # New passwords
    'mtmms_project.hashers.LaravelBcryptHasher',          # Legacy Laravel hashes
]

# ─────────────────────────────────────────
# Django REST Framework — JWT Auth
# Replaces Laravel Sanctum
# ─────────────────────────────────────────
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_PAGINATION_CLASS': 'mtmms_project.pagination.LaravelCompatiblePagination',
    'PAGE_SIZE': 50,
}

# JWT token lifetimes (generous, like Sanctum persistent tokens)
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME':  timedelta(days=7),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=30),
    'AUTH_HEADER_TYPES': ('Bearer',),  # Same as Sanctum: Authorization: Bearer <token>
}

# ─────────────────────────────────────────
# CORS — Allow React (5173 / 5174), Flutter Web, and LAN devices
# ─────────────────────────────────────────
CORS_ALLOW_ALL_ORIGINS = True
CORS_ALLOW_CREDENTIALS = True

CORS_ALLOW_HEADERS = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'origin',
    'x-requested-with',
]

# ─────────────────────────────────────────
# Static / Misc
# ─────────────────────────────────────────
LANGUAGE_CODE = 'en-us'
TIME_ZONE     = 'Asia/Kolkata'
USE_I18N      = True
USE_TZ        = True
STATIC_URL    = '/static/'
STATIC_ROOT   = BASE_DIR / 'staticfiles'
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

