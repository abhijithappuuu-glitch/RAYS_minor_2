import os
from datetime import timedelta


class Config:
    """Base configuration with validation."""
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')
    
    @staticmethod
    def validate_production_config():
        """Validate required environment variables in production."""
        if os.getenv('FLASK_ENV') == 'production':
            if not os.getenv('SECRET_KEY') or os.getenv('SECRET_KEY') == 'dev-secret-key-change-in-production':
                raise ValueError('❌ Production Error: SECRET_KEY must be set and secure')
            if not os.getenv('VALID_API_KEYS'):
                raise ValueError('❌ Production Error: VALID_API_KEYS environment variable is required')

    # API Security
    API_KEY_HEADER = 'X-API-Key'
    VALID_API_KEYS = set(filter(None, os.getenv('VALID_API_KEYS', '').split(',')))

    # Database
    basedir = os.path.abspath(os.path.dirname(os.path.dirname(__file__)))
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URL', 'sqlite:///' + os.path.join(basedir, 'rays.db'))
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # Rate Limiting
    RATELIMIT_STORAGE_URL = os.getenv('REDIS_URL', 'redis://localhost:6379')
    RATELIMIT_DEFAULT = "100 per hour"
    RATELIMIT_PREDICT = "30 per minute"

    # ML Model
    MODEL_PATH = os.path.join(os.path.dirname(__file__), 'models', 'stress_predictor.pkl')
    MODEL_VERSION = '2.0.0'

    # Logging
    LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO')
    LOG_FORMAT = 'json'

    # CORS
    CORS_ORIGINS = ['*']  # Default to all origins, restrict in production via env var

    # Request Validation
    MAX_CONTENT_LENGTH = 1 * 1024 * 1024  # 1MB
    REQUEST_TIMEOUT = 30  # seconds

    # Security Headers
    SECURITY_HEADERS = {
        'X-Content-Type-Options': 'nosniff',
        'X-Frame-Options': 'DENY',
        'X-XSS-Protection': '1; mode=block',
        'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
        'Content-Security-Policy': "default-src 'self'",
    }

class ProductionConfig(Config):
    DEBUG = False
    TESTING = False
    VALID_API_KEYS = set(filter(None, os.getenv('VALID_API_KEYS', '').split(',')))

class DevelopmentConfig(Config):
    DEBUG = True
    TESTING = False
    RATELIMIT_ENABLED = False
    VALID_API_KEYS = {'dev-test-key', 'test-key'}

class TestingConfig(Config):
    TESTING = True
    RATELIMIT_ENABLED = False
    SQLALCHEMY_DATABASE_URI = 'sqlite:///:memory:'
    CORS_ORIGINS = ['*']
    VALID_API_KEYS = {'dev-test-key', 'test-key'}

config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig,
}
