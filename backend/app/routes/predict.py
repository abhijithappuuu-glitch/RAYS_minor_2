from flask import Blueprint, request, jsonify, current_app
from marshmallow import ValidationError
from app.schemas.stress_schema import StressPredictSchema, StressPredictResponseSchema
from app.models.ml_model import StressPredictor
from app.middleware.auth import require_api_key
from app import limiter
from app.database import db
from app.models.db_models import UserTelemetry

predict_bp = Blueprint('predict', __name__)

def get_ml_model():
    """Thread-safe ML model loader using Flask's g context (request-scoped storage)."""
    from flask import g
    if 'ml_model' not in g:
        model_path = current_app.config.get('MODEL_PATH')
        g.ml_model = StressPredictor(model_path)
    return g.ml_model

@predict_bp.route('/predict', methods=['POST'])
@limiter.limit("30 per minute")
@require_api_key
def predict_stress():
    """
    Predict stress level from behavioral and health data.
    ---
    tags:
      - Predictions
    security:
      - ApiKeyAuth: []
    parameters:
      - in: header
        name: X-API-Key
        type: string
        required: true
        description: Valid API key
      - in: body
        name: body
        required: true
        schema:
          type: object
          required:
            - device_id
            - social_minutes
            - late_night_usage
            - sleep_minutes
            - doom_scroll_flag
            - pickup_count
          properties:
            device_id:
              type: string
              example: device-uuid-12345
            social_minutes:
              type: integer
              minimum: 0
              maximum: 1440
              example: 120
            late_night_usage:
              type: boolean
              example: true
            sleep_minutes:
              type: integer
              minimum: 0
              maximum: 960
              example: 360
            doom_scroll_flag:
              type: boolean
              example: false
            pickup_count:
              type: integer
              minimum: 0
              maximum: 500
              example: 80
            exercise_minutes:
              type: integer
              minimum: 0
              maximum: 480
            resting_heart_rate:
              type: integer
              minimum: 40
              maximum: 200
            hrv_score:
              type: number
              minimum: 0
              maximum: 200
            total_screen_minutes:
              type: integer
              minimum: 0
              maximum: 1440
    responses:
      200:
        description: Successful prediction
        schema:
          type: object
          properties:
            stress_score:
              type: integer
              example: 65
            risk_level:
              type: string
              enum: [low, medium, high]
              example: medium
            confidence:
              type: number
              example: 0.92
            contextual_message:
              type: string
              example: You're doom-scrolling late at night...
            model_version:
              type: string
              example: '3.0.0'
            timestamp:
              type: string
              format: date-time
      400:
        description: Validation error
        schema:
          type: object
          properties:
            error:
              type: string
              example: Validation failed
            details:
              type: object
      401:
        description: Invalid or missing API key
        schema:
          type: object
          properties:
            error:
              type: string
              example: Invalid API key
      429:
        description: Rate limit exceeded
        schema:
          type: object
          properties:
            error:
              type: string
              example: Rate limit exceeded
            retry_after:
              type: integer
      500:
        description: Server error
        schema:
          type: object
          properties:
            error:
              type: string
              example: Prediction failed
    """
    try:
        schema = StressPredictSchema()
        data = schema.load(request.json)

        model = get_ml_model()
        result = model.predict(data)
        
        # Save telemetry
        try:
            telemetry = UserTelemetry(
                device_id=data['device_id'],
                sleep_minutes=data.get('sleep_minutes'),
                total_screen_minutes=data.get('total_screen_minutes'),
                social_minutes=data.get('social_minutes'),
                exercise_minutes=data.get('exercise_minutes'),
                pickup_count=data.get('pickup_count'),
                resting_heart_rate=data.get('resting_heart_rate'),
                hrv_score=data.get('hrv_score'),
                doom_scroll_flag=data.get('doom_scroll_flag'),
                late_night_usage=data.get('late_night_usage'),
                predicted_stress_score=result['stress_score'],
                predicted_risk_level=result['risk_level']
            )
            db.session.add(telemetry)
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            current_app.logger.error(f"Failed to save telemetry: {e}")

        response_schema = StressPredictResponseSchema()
        validated_result = response_schema.dump(result)

        return jsonify(validated_result), 200

    except ValidationError as err:
        return jsonify({'error': 'Validation failed', 'details': err.messages}), 400
    except Exception as e:
        current_app.logger.error(f'Prediction error: {str(e)}')
        return jsonify({'error': 'Prediction failed'}), 500
