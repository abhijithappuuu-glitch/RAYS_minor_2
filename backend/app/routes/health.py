from flask import Blueprint, jsonify, current_app
import time
from datetime import datetime

health_bp = Blueprint('health', __name__)

start_time = time.time()


@health_bp.route('/health', methods=['GET'])
def health_check():
    """
    Health check endpoint for monitoring.

    Returns:
    {
        "status": "healthy",
        "uptime": float,
        "timestamp": string,
        "version": string
    }
    """
    uptime = time.time() - start_time

    return jsonify({
        'status': 'healthy',
        'uptime_seconds': round(uptime, 2),
        'timestamp': datetime.utcnow().isoformat(),
        'version': current_app.config['MODEL_VERSION'],
    }), 200


@health_bp.route('/ready', methods=['GET'])
def readiness():
    """Kubernetes readiness probe"""
    try:
        from app.routes.predict import get_ml_model
        model = get_ml_model()

        if model.model is not None:
            return jsonify({'status': 'ready'}), 200
        else:
            return jsonify({'status': 'not ready', 'reason': 'Model not loaded'}), 503
    except Exception as e:
        return jsonify({'status': 'not ready', 'reason': str(e)}), 503
