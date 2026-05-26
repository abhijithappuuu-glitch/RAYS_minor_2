import pytest
from app import create_app


@pytest.fixture
def client():
    app = create_app('testing')
    app.config['VALID_API_KEYS'] = {'test-key'}
    with app.test_client() as client:
        yield client


def test_predict_success(client):
    response = client.post(
        '/api/v1/predict',
        json={
            'social_minutes': 120,
            'late_night_usage': True,
            'sleep_minutes': 360,
            'doom_scroll_flag': False,
            'pickup_count': 50,
        },
        headers={'X-API-Key': 'test-key'},
    )

    assert response.status_code == 200
    data = response.get_json()
    assert 'stress_score' in data
    assert 'risk_level' in data
    assert data['risk_level'] in ['low', 'medium', 'high']


def test_predict_with_optional_fields(client):
    response = client.post(
        '/api/v1/predict',
        json={
            'social_minutes': 60,
            'late_night_usage': False,
            'sleep_minutes': 480,
            'doom_scroll_flag': False,
            'pickup_count': 30,
            'exercise_minutes': 45,
            'resting_heart_rate': 65,
            'total_screen_minutes': 180,
        },
        headers={'X-API-Key': 'test-key'},
    )

    assert response.status_code == 200
    data = response.get_json()
    assert 'confidence' in data
    assert 'model_version' in data


def test_predict_missing_api_key(client):
    response = client.post('/api/v1/predict', json={})
    assert response.status_code == 401


def test_predict_invalid_api_key(client):
    response = client.post(
        '/api/v1/predict',
        json={
            'social_minutes': 120,
            'late_night_usage': True,
            'sleep_minutes': 360,
            'doom_scroll_flag': False,
            'pickup_count': 50,
        },
        headers={'X-API-Key': 'wrong-key'},
    )
    assert response.status_code == 401


def test_predict_invalid_data(client):
    response = client.post(
        '/api/v1/predict',
        json={'invalid': 'data'},
        headers={'X-API-Key': 'test-key'},
    )
    assert response.status_code == 400


def test_predict_out_of_range(client):
    response = client.post(
        '/api/v1/predict',
        json={
            'social_minutes': 9999,  # exceeds max 1440
            'late_night_usage': True,
            'sleep_minutes': 360,
            'doom_scroll_flag': False,
            'pickup_count': 50,
        },
        headers={'X-API-Key': 'test-key'},
    )
    assert response.status_code == 400


def test_health_check(client):
    response = client.get('/api/v1/health')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'healthy'
    assert 'uptime_seconds' in data
    assert 'version' in data


def test_readiness_check(client):
    response = client.get('/api/v1/ready')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'ready'
