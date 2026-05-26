from app.database import db
from datetime import datetime

class UserTelemetry(db.Model):
    __tablename__ = 'user_telemetry'

    id = db.Column(db.Integer, primary_key=True)
    device_id = db.Column(db.String(255), index=True, nullable=False)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow, index=True)
    
    sleep_minutes = db.Column(db.Integer)
    total_screen_minutes = db.Column(db.Integer)
    social_minutes = db.Column(db.Integer)
    exercise_minutes = db.Column(db.Integer)
    pickup_count = db.Column(db.Integer)
    resting_heart_rate = db.Column(db.Integer)
    hrv_score = db.Column(db.Float)
    doom_scroll_flag = db.Column(db.Boolean)
    late_night_usage = db.Column(db.Boolean)
    
    predicted_stress_score = db.Column(db.Integer)
    predicted_risk_level = db.Column(db.String(50))

class UserFeedback(db.Model):
    __tablename__ = 'user_feedback'

    id = db.Column(db.Integer, primary_key=True)
    device_id = db.Column(db.String(255), index=True, nullable=False)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)
    
    reported_stress_level = db.Column(db.Integer, nullable=False) # 1-5 scale
    context = db.Column(db.String(500))
