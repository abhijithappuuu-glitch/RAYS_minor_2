from flask import Flask, jsonify
from flask_cors import CORS
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from prometheus_flask_exporter import PrometheusMetrics
import logging
from app.config import config
from app.utils.logger import setup_logger
from app.middleware.security import add_security_headers
from app.database import db

limiter = Limiter(
    key_func=get_remote_address,
    storage_uri="memory://",  # Use Redis in production
)

def create_app(config_name='default'):
    flask_app = Flask(__name__)
    
    # Load configuration
    try:
        flask_app.config.from_object(config[config_name])
        # Validate production configuration
        if config_name == 'production':
            from app.config import Config
            Config.validate_production_config()
    except ValueError as e:
        logging.error(f'Configuration Error: {str(e)}')
        raise
    except KeyError:
        raise ValueError(f'Unknown configuration: {config_name}')

    # Setup logging
    setup_logger(flask_app)

    # Initialize Database
    db.init_app(flask_app)
    with flask_app.app_context():
        import app.models.db_models
        db.create_all()

    # CORS
    CORS(flask_app, origins=flask_app.config.get('CORS_ORIGINS', ['*']))

    # Rate Limiting
    limiter.init_app(flask_app)

    # Prometheus Metrics
    metrics = PrometheusMetrics(flask_app)

    # Swagger/OpenAPI Documentation
    try:
        from app.docs import setup_swagger
        setup_swagger(flask_app)
    except Exception as e:
        flask_app.logger.warning(f'Swagger unavailable: {e}')

    # Security headers middleware
    flask_app.after_request(add_security_headers)

    # Register blueprints
    from app.routes.predict import predict_bp, load_model_assets
    from app.routes.health import health_bp
    from app.routes.feedback import feedback_bp

    flask_app.register_blueprint(predict_bp, url_prefix='/api/v1')
    flask_app.register_blueprint(health_bp, url_prefix='/api/v1')
    flask_app.register_blueprint(feedback_bp, url_prefix='/api/v1')

    # Pre-load ML model at startup (instant response on first request)
    with flask_app.app_context():
        load_model_assets()

    # Global error handlers
    @flask_app.errorhandler(400)
    def bad_request(e):
        return jsonify({'error': 'Bad Request', 'message': str(e)}), 400

    @flask_app.errorhandler(401)
    def unauthorized(e):
        return jsonify({'error': 'Unauthorized', 'message': 'Invalid API key'}), 401

    @flask_app.errorhandler(429)
    def ratelimit_handler(e):
        return jsonify({'error': 'Rate Limit Exceeded', 'message': str(e)}), 429

    @flask_app.errorhandler(500)
    def internal_error(e):
        flask_app.logger.error(f'Internal Server Error: {str(e)}')
        return jsonify({'error': 'Internal Server Error'}), 500

    return flask_app
