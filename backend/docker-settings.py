from .common import *

MEDIA_URL = "http://example/media/"
STATIC_URL = "http://example/static/"
ADMIN_MEDIA_PREFIX = "http://example/static/admin/"
SITES["front"]["scheme"] = "http"
SITES["front"]["domain"] = "example"

SECRET_KEY = "theveryultratopsecretkey"

DEBUG = False
TEMPLATE_DEBUG = False
PUBLIC_REGISTER_ENABLED = True

DEFAULT_FROM_EMAIL = "no-reply@example.com"
SERVER_EMAIL = DEFAULT_FROM_EMAIL

# Uncomment and populate with proper connection parameters
# for enable email sending.
#EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"
#EMAIL_USE_TLS = False
#EMAIL_HOST = "localhost"
#EMAIL_HOST_USER = ""
#EMAIL_HOST_PASSWORD = ""
#EMAIL_PORT = 25

# Uncomment and populate with proper connection parameters
# for enable github login/singin.
#GITHUB_API_CLIENT_ID = "yourgithubclientid"
#GITHUB_API_CLIENT_SECRET = "yourgithubclientsecret"



DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql_psycopg2",
        "NAME": "taiga",
        "HOST": "postgres",
        "USER": "taiga",
        "PASSWORD": "thisisthetaigapassword",
    }
}


SECRET_KEY = "!@akljfREdsjfhuladsjkfalu535363"


