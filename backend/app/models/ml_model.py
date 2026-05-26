import joblib
import numpy as np
import pandas as pd
import os
from datetime import datetime, timedelta
from app.database import db
from app.models.db_models import UserTelemetry

class StressPredictor:
    """LightGBM-based stress prediction model"""

    def __init__(self, model_path=None):
        self.model = None
        self.scaler = None
        self.feature_cols = None
        self.model_version = '3.0.0'

        if model_path and os.path.exists(model_path):
            self.load_model(model_path)
        else:
            print(f"WARNING: Model not found at {model_path}. Please run train_model.py.")
            self.model = None

    def get_dynamic_baselines(self, device_id: str) -> dict:
        """Query DB for 30-day moving average baselines (Feature 1)"""
        thirty_days_ago = datetime.utcnow() - timedelta(days=30)
        
        # Note: In production with many rows, this should be an aggregate query
        history = UserTelemetry.query.filter(
            UserTelemetry.device_id == device_id,
            UserTelemetry.timestamp >= thirty_days_ago
        ).all()
        
        if not history or len(history) < 3:
            return {
                "baseline_sleep": 420,
                "baseline_screen": 300,
                "baseline_hr": 72,
                "baseline_pickups": 80,
                "baseline_hrv": 50.0
            }
            
        return {
            "baseline_sleep": sum(h.sleep_minutes or 420 for h in history) / len(history),
            "baseline_screen": sum(h.total_screen_minutes or 300 for h in history) / len(history),
            "baseline_hr": sum(h.resting_heart_rate or 72 for h in history) / len(history),
            "baseline_pickups": sum(h.pickup_count or 80 for h in history) / len(history),
            "baseline_hrv": sum(h.hrv_score or 50.0 for h in history) / len(history)
        }

    def add_personalized_features(self, df: pd.DataFrame, baselines: dict) -> pd.DataFrame:
        """Add deviation-from-baseline features."""
        d = df.copy()

        d["baseline_sleep"] = baselines["baseline_sleep"]
        d["baseline_screen"] = baselines["baseline_screen"]
        d["baseline_hr"] = baselines["baseline_hr"]
        d["baseline_pickups"] = baselines["baseline_pickups"]

        d["sleep_delta"] = d["sleep_minutes"] - d["baseline_sleep"]
        d["screen_delta"] = d["total_screen_minutes"] - d["baseline_screen"]
        d["hr_delta"] = d["resting_heart_rate"] - d["baseline_hr"]
        d["pickup_delta"] = d["pickup_count"] - d["baseline_pickups"]
        
        # HRV Feature
        if "hrv_score" in d.columns:
            d["baseline_hrv"] = baselines["baseline_hrv"]
            d["hrv_delta"] = d["hrv_score"] - d["baseline_hrv"]

        d["screen_sleep_ratio"] = d["total_screen_minutes"] / (d["sleep_minutes"] + 1e-6)
        d["social_screen_ratio"] = d["social_minutes"] / (d["total_screen_minutes"] + 1e-6)

        d["low_sleep_flag"] = (d["sleep_minutes"] < 360).astype(int)
        d["high_screen_flag"] = (d["total_screen_minutes"] > 420).astype(int)
        d["high_hr_flag"] = (d["resting_heart_rate"] > 85).astype(int)

        recovery = d["exercise_minutes"] + d["sleep_minutes"] / 10 - d["total_screen_minutes"] / 20
        if "hrv_score" in d.columns:
            recovery += d["hrv_score"] / 10
        d["recovery_score"] = recovery

        return d

    def generate_context_message(self, df: pd.DataFrame, risk_level: str) -> str:
        """Generate context-aware interventions (Feature 3)"""
        row = df.iloc[0]
        if risk_level == 'low':
            return "You're maintaining a great balance today! Keep it up."
            
        if row.get('doom_scroll_flag', 0) == 1 and row.get('late_night_usage', 0) == 1:
            return "You're doom-scrolling late at night. This severely impacts your recovery. Put the phone away."
            
        if row.get('screen_delta', 0) > 60 and row.get('social_screen_ratio', 0) > 0.6:
            return f"Your screen time is {int(row['screen_delta'])} mins above your normal, mostly on social media. Try Focus Mode."
            
        if row.get('sleep_delta', 0) < -60 and row.get('hrv_delta', 0) < -10:
            return "Your sleep is below your baseline and your HRV indicates physical strain. Prioritize rest today."
        
        return "We've detected elevated stress patterns in your routine. Take a quick break."

    def predict(self, features):
        if self.model is None or self.scaler is None:
            return {
                'stress_score': 0, 'risk_level': 'low', 'confidence': 0.0,
                'contextual_message': 'System unavailable', 'model_version': 'fallback',
                'timestamp': datetime.utcnow().isoformat()
            }

        device_id = features.get('device_id', 'unknown')
        raw_data = {
            'sleep_minutes': float(features.get('sleep_minutes', 420) or 420),
            'total_screen_minutes': float(features.get('total_screen_minutes', 0) or 0),
            'social_minutes': float(features.get('social_minutes', 0) or 0),
            'exercise_minutes': float(features.get('exercise_minutes', 0) or 0),
            'pickup_count': float(features.get('pickup_count', 0) or 0),
            'resting_heart_rate': float(features.get('resting_heart_rate', 70) or 70),
            'hrv_score': float(features.get('hrv_score', 50.0) or 50.0),
            'doom_scroll_flag': 1.0 if features.get('doom_scroll_flag') else 0.0,
            'late_night_usage': 1.0 if features.get('late_night_usage') else 0.0,
        }
        df = pd.DataFrame([raw_data])

        baselines = self.get_dynamic_baselines(device_id)
        df_engineered = self.add_personalized_features(df, baselines)

        # Ensure we only pass columns the model was trained on
        # (Allows fallback if model was trained before HRV was added)
        X = df_engineered[[col for col in self.feature_cols if col in df_engineered.columns]]

        # Safety check if model expects features we don't have
        missing_cols = set(self.feature_cols) - set(X.columns)
        if missing_cols:
            for col in missing_cols:
                X[col] = 0.0
        X = X[self.feature_cols]

        X_scaled = self.scaler.transform(X)
        probabilities = self.model.predict_proba(X_scaled)[0]
        predicted_class = int(np.argmax(probabilities))
        confidence = float(probabilities[predicted_class])

        if predicted_class == 2:
            risk_level, stress_score = 'high', int(66 + (confidence * 34))
        elif predicted_class == 1:
            risk_level, stress_score = 'medium', int(36 + (confidence * 29))
        else:
            risk_level, stress_score = 'low', int(max(0, 35 - (confidence * 35)))

        contextual_message = self.generate_context_message(df_engineered, risk_level)

        return {
            'stress_score': min(100, max(0, stress_score)),
            'risk_level': risk_level,
            'confidence': round(confidence, 3),
            'contextual_message': contextual_message,
            'model_version': self.model_version,
            'timestamp': datetime.utcnow().isoformat(),
        }

    def load_model(self, path):
        bundle = joblib.load(path)
        self.model = bundle.get('model')
        self.scaler = bundle.get('scaler')
        self.feature_cols = bundle.get('feature_cols')
        if 'version' in bundle:
            self.model_version = bundle['version']
