from flask import Blueprint, jsonify, request, current_app
import joblib
import numpy as np
import os

predict_bp = Blueprint('predict', __name__)

# ==========================================
# GLOBAL MEMORY
# ==========================================
model = None
scaler = None
feature_cols = None


def load_model_assets():
    global model, scaler, feature_cols
    if model is not None:
        return

    model_path = os.path.join(
        os.path.dirname(os.path.abspath(__file__)),
        '..', 'models', 'stress_predictor.pkl'
    )
    model_path = os.path.normpath(model_path)

    try:
        bundle = joblib.load(model_path)
        model = bundle['model']
        scaler = bundle['scaler']
        feature_cols = bundle.get('feature_cols')
        print(f"ML Model v{bundle.get('version', '?')} loaded from {model_path}")
    except Exception as e:
        print(f"Error loading model: {e}")


STRESS_LABELS = {0: "Low", 1: "Medium", 2: "High"}


# ==========================================
# FEATURE ENGINEERING (matches train_model.py)
# ==========================================
def build_features(data):
    """
    Takes the raw JSON from Flutter and builds the EXACT 25 features
    that the trained LightGBM model expects.
    Uses safe defaults so the server never crashes if a field is missing.
    """
    # 9 raw features
    sleep = data.get('sleep_minutes', 420)
    screen = data.get('total_screen_minutes', data.get('screen_time_minutes', 300))
    social = data.get('social_minutes', data.get('social_media_usage_minutes', 60))
    exercise = data.get('exercise_minutes', 30)
    pickups = data.get('pickup_count', data.get('unlock_count', 50))
    hr = data.get('resting_heart_rate', data.get('avg_heart_rate', 72))
    hrv = data.get('hrv_score', 50.0)
    doom = int(bool(data.get('doom_scroll_flag', False)))
    late = int(bool(data.get('late_night_usage', False)))

    # Static baselines (in production, these come from DB)
    bl_sleep = 420
    bl_screen = 300
    bl_hr = 72
    bl_pickups = 80
    bl_hrv = 50.0

    # Deltas
    sleep_delta = sleep - bl_sleep
    screen_delta = screen - bl_screen
    hr_delta = hr - bl_hr
    pickup_delta = pickups - bl_pickups
    hrv_delta = hrv - bl_hrv

    # Ratios
    screen_sleep_ratio = screen / (sleep + 0.000001)
    social_screen_ratio = social / (screen + 0.000001)

    # Binary flags
    low_sleep_flag = 1 if sleep < 360 else 0
    high_screen_flag = 1 if screen > 420 else 0
    high_hr_flag = 1 if hr > 85 else 0

    # Composite recovery score
    recovery_score = exercise + sleep / 10 - screen / 20 + hrv / 10

    # Return as a flat list in the EXACT order train_model.py generates
    return [
        sleep, screen, social, exercise, pickups, hr, hrv, doom, late,
        bl_sleep, bl_screen, bl_hr, bl_pickups, bl_hrv,
        sleep_delta, screen_delta, hr_delta, pickup_delta, hrv_delta,
        screen_sleep_ratio, social_screen_ratio,
        low_sleep_flag, high_screen_flag, high_hr_flag,
        recovery_score,
    ]


# ==========================================
# DYNAMIC AI ADVICE ENGINE
# ==========================================
def generate_ai_advice(data, stress_level):
    if stress_level == "Low":
        return "Your metrics look great! Keep up the good habits and stay consistent."

    screen_time = data.get('total_screen_minutes', data.get('screen_time_minutes', 0))
    sleep_time = data.get('sleep_minutes', 0)
    social_media = data.get('social_minutes', data.get('social_media_usage_minutes', 0))
    hr = data.get('resting_heart_rate', data.get('avg_heart_rate', 0))
    doom = data.get('doom_scroll_flag', False)
    late = data.get('late_night_usage', False)

    if doom and late:
        return "You're doom-scrolling late at night. Put the phone in another room and sleep."

    if screen_time > 300 and sleep_time < 360:
        return "High screen time is heavily impacting your sleep schedule. Put the phone away 1 hour before bed tonight."

    if social_media > 120:
        return "Your social media usage is elevated, which correlates with your stress spike. Try a 30-minute digital detox."

    if hr > 85:
        return "Your average heart rate is elevated today. Take a 5-minute breathing break to physically reset your nervous system."

    if sleep_time < 300:
        return "Severe sleep deficit detected. Your primary goal today should be resting and getting to bed early."

    if late:
        return "Late-night phone usage disrupts your circadian rhythm. Try winding down 30 minutes earlier tonight."

    return "Your physiological metrics show elevated stress. Hydrate, take short breaks, and prioritize your workload."


# ==========================================
# THE PREDICTION ENDPOINT
# ==========================================
@predict_bp.route('/predict', methods=['POST'])
def predict_stress():
    load_model_assets()

    if not model or not scaler:
        return jsonify({"success": False, "error": "AI Model not initialized"}), 500

    try:
        data = request.json

        # Build 25 engineered features matching the trained model
        features = build_features(data)
        raw_array = np.array([features])

        # Scale and predict
        scaled_features = scaler.transform(raw_array)
        prediction_num = int(model.predict(scaled_features)[0])
        probabilities = model.predict_proba(scaled_features)[0]
        confidence = float(max(probabilities))

        # Score: probability-weighted 0-100
        stress_score = int(probabilities[0] * 0 + probabilities[1] * 50 + probabilities[2] * 100)
        stress_score = max(0, min(100, stress_score))

        # Label and advice
        stress_level_text = STRESS_LABELS.get(prediction_num, "Medium")
        ai_advice = generate_ai_advice(data, stress_level_text)

        return jsonify({
            "success": True,
            "stress_level": stress_level_text,
            "stress_score": stress_score,
            "risk_level": stress_level_text.lower(),
            "confidence": round(confidence, 3),
            "ai_advice": ai_advice,
            "contextual_message": ai_advice,
            "model_version": "3.0.0"
        }), 200

    except Exception as e:
        print(f"Prediction Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({"success": False, "error": str(e)}), 400
