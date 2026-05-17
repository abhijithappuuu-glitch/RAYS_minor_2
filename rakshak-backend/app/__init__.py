from flask import Flask, jsonify
from flask_cors import CORS
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from prometheus_flask_exporter import PrometheusMetrics
import logging
from app.config import config
from app.utils.logger import setup_logger
from app.middleware.security import add_security_headers

limiter = Limiter(
    key_func=get_remote_address,
    storage_uri="memory://",  # Use Redis in production
)


def create_app(config_name='default'):
    app = Flask(__name__)
    app.config.from_object(config[config_name])

    # Setup logging
    setup_logger(app)

    # CORS
    CORS(app, origins=app.config['CORS_ORIGINS'])

    # Rate Limiting
    limiter.init_app(app)

    # Prometheus Metrics
    metrics = PrometheusMetrics(app)

    # Security headers middleware
    app.after_request(add_security_headers)

    # Register blueprints
    from app.routes.predict import predict_bp
    from app.routes.health import health_bp

    app.register_blueprint(predict_bp, url_prefix='/api/v1')
    app.register_blueprint(health_bp, url_prefix='/api/v1')

    # Global error handlers
    @app.errorhandler(400)
    def bad_request(e):
        return jsonify({'error': 'Bad Request', 'message': str(e)}), 400

    @app.errorhandler(401)
    def unauthorized(e):
        return jsonify({'error': 'Unauthorized', 'message': 'Invalid API key'}), 401

    @app.errorhandler(429)
    def ratelimit_handler(e):
        return jsonify({'error': 'Rate Limit Exceeded', 'message': str(e)}), 429

    @app.errorhandler(500)
    def internal_error(e):
        app.logger.error(f'Internal Server Error: {str(e)}')
        return jsonify({'error': 'Internal Server Error'}), 500

    return app
