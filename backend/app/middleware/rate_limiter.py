from flask import request, jsonify
from functools import wraps
import time
from collections import defaultdict


class InMemoryRateLimiter:
    """Simple in-memory rate limiter as fallback when Redis unavailable"""

    def __init__(self, max_requests=30, window_seconds=60):
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self._requests = defaultdict(list)

    def is_allowed(self, key):
        now = time.time()
        window_start = now - self.window_seconds

        # Clean old entries
        self._requests[key] = [
            t for t in self._requests[key] if t > window_start
        ]

        if len(self._requests[key]) >= self.max_requests:
            return False

        self._requests[key].append(now)
        return True


_limiter = InMemoryRateLimiter()


def rate_limit(max_requests=30, window_seconds=60):
    """Decorator-based rate limiter using client IP"""
    def decorator(f):
        limiter = InMemoryRateLimiter(max_requests, window_seconds)

        @wraps(f)
        def decorated_function(*args, **kwargs):
            client_ip = request.remote_addr
            if not limiter.is_allowed(client_ip):
                return jsonify({
                    'error': 'Rate limit exceeded',
                    'retry_after': window_seconds,
                }), 429
            return f(*args, **kwargs)

        return decorated_function
    return decorator
