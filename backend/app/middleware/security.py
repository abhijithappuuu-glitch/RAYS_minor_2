from flask import current_app


def add_security_headers(response):
    """Add security headers to all responses"""
    for header, value in current_app.config['SECURITY_HEADERS'].items():
        response.headers[header] = value
    return response
