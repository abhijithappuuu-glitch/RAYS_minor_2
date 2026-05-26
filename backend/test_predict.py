import json
from app import create_app

a = create_app('development')
client = a.test_client()

scenarios = [
    {"name": "HEALTHY USER", "data": {
        "sleep_minutes": 480, "total_screen_minutes": 120,
        "social_minutes": 30, "exercise_minutes": 60,
        "pickup_count": 20, "resting_heart_rate": 62, "hrv_score": 70
    }},
    {"name": "HIGH STRESS", "data": {
        "sleep_minutes": 240, "total_screen_minutes": 500,
        "social_minutes": 200, "exercise_minutes": 0,
        "pickup_count": 150, "resting_heart_rate": 95, "hrv_score": 25,
        "doom_scroll_flag": True, "late_night_usage": True
    }},
    {"name": "MODERATE", "data": {
        "sleep_minutes": 360, "total_screen_minutes": 350,
        "social_minutes": 140, "exercise_minutes": 15,
        "pickup_count": 80, "resting_heart_rate": 78, "hrv_score": 45
    }},
]

for s in scenarios:
    r = client.post('/api/v1/predict',
                    data=json.dumps(s['data']),
                    content_type='application/json')
    result = r.get_json()
    print(f"\n=== {s['name']} ===")
    print(f"  Score: {result['stress_score']}/100")
    print(f"  Level: {result['stress_level']}")
    print(f"  Advice: {result['ai_advice']}")
    print(f"  Confidence: {result['confidence']}")
