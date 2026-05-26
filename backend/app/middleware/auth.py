from functools import wraps
from flask import request, current_app, jsonify
import hashlib
import hmac
import time


def require_api_key(f):
    """Decorator to validate API key"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        api_key = request.headers.get(current_app.config['API_KEY_HEADER'])

        if not api_key:
            current_app.logger.warning(f'Missing API key from {request.remote_addr}')
            return jsonify({'error': 'API key required'}), 401

        if api_key not in current_app.config['VALID_API_KEYS']:
            current_app.logger.warning(f'Invalid API key attempt from {request.remote_addr}')
            return jsonify({'error': 'Invalid API key'}), 401

        return f(*args, **kwargs)

    return decorated_function


def verify_request_signature(f):
    """Verify HMAC signature for replay attack protection"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        signature = request.headers.get('X-Request-Signature')
        timestamp = request.headers.get('X-Request-Timestamp')
        nonce = request.headers.get('X-Request-Nonce')

        if not all([signature, timestamp, nonce]):
            return jsonify({'error': 'Missing security headers'}), 401

        # Check timestamp (prevent replay attacks)
        try:
            request_time = int(timestamp)
            current_time = int(time.time())
            if abs(current_time - request_time) > 300:  # 5 minutes tolerance
                return jsonify({'error': 'Request expired'}), 401
        except ValueError:
            return jsonify({'error': 'Invalid timestamp'}), 401

        # Verify HMAC signature
        # The mobile client signs with the API key, so we must validate using
        # the same key — NOT Flask's SECRET_KEY.
        api_key = request.headers.get(current_app.config['API_KEY_HEADER'], '')
        secret = api_key.encode()
        message = f"{timestamp}{nonce}{request.get_data().decode()}".encode()
        expected_signature = hmac.new(secret, message, hashlib.sha256).hexdigest()

        if not hmac.compare_digest(signature, expected_signature):
            current_app.logger.warning(f'Invalid signature from {request.remote_addr}')
            return jsonify({'error': 'Invalid signature'}), 401

        return f(*args, **kwargs)

    return decorated_function
