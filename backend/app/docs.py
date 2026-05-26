"""API Documentation using Flasgger (Swagger)."""
from flasgger import Swagger
from flask import Blueprint

swagger_bp = Blueprint('swagger', __name__)


def setup_swagger(app):
    """Initialize Swagger/OpenAPI documentation."""
    swagger = Swagger(
        app,
        title='RAYS Stress Prediction API',
        version='3.0.0',
        description='Production-grade ML API for stress prediction and wellness monitoring',
        contact={
            'name': 'RAYS Team',
            'email': 'support@rays.local',
            'url': 'https://rays.local',
        },
        license={
            'name': 'MIT',
            'url': 'https://opensource.org/licenses/MIT',
        },
        specs_route='/api/docs',
    )
    
    return swagger


def create_predict_schema():
    """Generate Swagger schema for predict endpoint."""
    return {
        "type": "object",
        "required": [
            "device_id",
            "social_minutes",
            "late_night_usage",
            "sleep_minutes",
            "doom_scroll_flag",
            "pickup_count",
        ],
        "properties": {
            "device_id": {
                "type": "string",
                "description": "Unique device identifier",
                "example": "device-uuid-12345",
            },
            "social_minutes": {
                "type": "integer",
                "minimum": 0,
                "maximum": 1440,
                "description": "Minutes spent on social media today",
                "example": 120,
            },
            "late_night_usage": {
                "type": "boolean",
                "description": "Phone used between 12–4 AM",
                "example": True,
            },
            "sleep_minutes": {
                "type": "integer",
                "minimum": 0,
                "maximum": 960,
                "description": "Total sleep duration in minutes",
                "example": 360,
            },
            "doom_scroll_flag": {
                "type": "boolean",
                "description": "Extended uninterrupted social scrolling detected",
                "example": False,
            },
            "pickup_count": {
                "type": "integer",
                "minimum": 0,
                "maximum": 500,
                "description": "Number of phone unlocks today",
                "example": 80,
            },
            "exercise_minutes": {
                "type": "integer",
                "minimum": 0,
                "maximum": 480,
                "description": "Minutes of physical activity (optional)",
                "example": 30,
            },
            "resting_heart_rate": {
                "type": "integer",
                "minimum": 40,
                "maximum": 200,
                "description": "BPM from health data (optional)",
                "example": 72,
            },
            "hrv_score": {
                "type": "number",
                "minimum": 0,
                "maximum": 200,
                "description": "Heart rate variability score (optional)",
                "example": 50.5,
            },
            "total_screen_minutes": {
                "type": "integer",
                "minimum": 0,
                "maximum": 1440,
                "description": "Total screen-on time in minutes (optional)",
                "example": 300,
            },
        },
    }


def create_predict_response_schema():
    """Generate Swagger schema for predict response."""
    return {
        "type": "object",
        "properties": {
            "stress_score": {
                "type": "integer",
                "description": "Predicted stress score (0-100)",
                "example": 65,
            },
            "risk_level": {
                "type": "string",
                "enum": ["low", "medium", "high"],
                "description": "Risk level category",
                "example": "medium",
            },
            "confidence": {
                "type": "number",
                "minimum": 0,
                "maximum": 1,
                "description": "Confidence of the prediction",
                "example": 0.92,
            },
            "contextual_message": {
                "type": "string",
                "description": "Context-aware intervention message",
                "example": "You're doom-scrolling late at night...",
            },
            "model_version": {
                "type": "string",
                "description": "Version of the ML model used",
                "example": "3.0.0",
            },
            "timestamp": {
                "type": "string",
                "format": "date-time",
                "description": "ISO 8601 timestamp of prediction",
                "example": "2026-05-25T10:30:00Z",
            },
        },
    }
