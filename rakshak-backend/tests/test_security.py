import pytest
from app import create_app


@pytest.fixture
def client():
    app = create_app('testing')
    app.config['VALID_API_KEYS'] = {'test-key'}
    with app.test_client() as client:
        yield client


def test_security_headers_present(client):
    """Verify all security headers are set on responses"""
    response = client.get('/api/v1/health')

    assert response.headers.get('X-Content-Type-Options') == 'nosniff'
    assert response.headers.get('X-Frame-Options') == 'DENY'
    assert response.headers.get('X-XSS-Protection') == '1; mode=block'
    assert 'Strict-Transport-Security' in response.headers
    assert 'Content-Security-Policy' in response.headers


def test_api_key_required_on_predict(client):
    """Predict endpoint must reject requests without API key"""
    response = client.post(
        '/api/v1/predict',
        json={
            'social_minutes': 100,
            'late_night_usage': False,
            'sleep_minutes': 420,
            'doom_scroll_flag': False,
            'pickup_count': 30,
        },
    )
    assert response.status_code == 401
    data = response.get_json()
    assert 'error' in data


def test_health_does_not_require_api_key(client):
    """Health endpoint should be publicly accessible"""
    response = client.get('/api/v1/health')
    assert response.status_code == 200


def test_max_content_length(client):
    """Requests exceeding MAX_CONTENT_LENGTH should be rejected"""
    # Generate a payload larger than 1MB
    large_payload = {'data': 'x' * (2 * 1024 * 1024)}
    response = client.post(
        '/api/v1/predict',
        json=large_payload,
        headers={'X-API-Key': 'test-key'},
    )
    # Flask returns 413 for oversized requests
    assert response.status_code in [400, 413]


def test_invalid_json_body(client):
    """Non-JSON requests should return 400"""
    response = client.post(
        '/api/v1/predict',
        data='this is not json',
        content_type='text/plain',
        headers={'X-API-Key': 'test-key'},
    )
    assert response.status_code in [400, 415]


def test_combined_sleep_screen_validation(client):
    """Sleep + screen time exceeding 24h should fail validation"""
    response = client.post(
        '/api/v1/predict',
        json={
            'social_minutes': 100,
            'late_night_usage': False,
            'sleep_minutes': 800,
            'doom_scroll_flag': False,
            'pickup_count': 30,
            'total_screen_minutes': 800,
        },
        headers={'X-API-Key': 'test-key'},
    )
    assert response.status_code == 400
