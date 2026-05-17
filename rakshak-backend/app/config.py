import os
from datetime import timedelta


class Config:
    """Base configuration"""
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')

    # API Security
    API_KEY_HEADER = 'X-API-Key'
    # Filter out the empty string that results when the env var is unset,
    # so an empty header can never accidentally pass authentication.
    VALID_API_KEYS = set(filter(None, os.getenv('VALID_API_KEYS', '').split(',')))

    # Rate Limiting
    RATELIMIT_STORAGE_URL = os.getenv('REDIS_URL', 'redis://localhost:6379')
    RATELIMIT_DEFAULT = "100 per hour"
    RATELIMIT_PREDICT = "30 per minute"

    # ML Model
    MODEL_PATH = os.path.join(os.path.dirname(__file__), 'models', 'stress_predictor.pkl')
    MODEL_VERSION = '1.0.0'

    # Logging
    LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO')
    LOG_FORMAT = 'json'

    # CORS
    CORS_ORIGINS = os.getenv('CORS_ORIGINS', '*').split(',')

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
    # Inherit the safe default from Config; override only when env var is set.
    VALID_API_KEYS = set(filter(None, os.getenv('VALID_API_KEYS', '').split(',')))


class DevelopmentConfig(Config):
    DEBUG = True
    TESTING = False
    RATELIMIT_ENABLED = False
    VALID_API_KEYS = {'dev-test-key', 'test-key'}


class TestingConfig(Config):
    TESTING = True
    RATELIMIT_ENABLED = False


config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig,
}
