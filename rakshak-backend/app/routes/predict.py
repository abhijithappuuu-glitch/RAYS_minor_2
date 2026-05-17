from flask import Blueprint, request, jsonify, current_app
from marshmallow import ValidationError
from app.schemas.stress_schema import StressPredictSchema, StressPredictResponseSchema
from app.models.ml_model import StressPredictor
from app.middleware.auth import require_api_key
from app import limiter

predict_bp = Blueprint('predict', __name__)

# Initialize ML model (singleton)
ml_model = None


def get_ml_model():
    global ml_model
    if ml_model is None:
        model_path = current_app.config.get('MODEL_PATH')
        ml_model = StressPredictor(model_path)
    return ml_model


@predict_bp.route('/predict', methods=['POST'])
@limiter.limit("30 per minute")
@require_api_key
def predict_stress():
    """
    Predict stress level from behavioral data.

    Request Body:
    {
        "social_minutes": int,
        "late_night_usage": bool,
        "sleep_minutes": int,
        "doom_scroll_flag": bool,
        "pickup_count": int,
        "exercise_minutes": int (optional),
        "resting_heart_rate": int (optional)
    }

    Response:
    {
        "stress_score": int (0-100),
        "risk_level": "low" | "medium" | "high",
        "confidence": float,
        "model_version": string,
        "timestamp": string
    }
    """

    try:
        # Validate input
        schema = StressPredictSchema()
        data = schema.load(request.json)

        current_app.logger.info(
            'Prediction request received',
            extra={
                'client_ip': request.remote_addr,
                'features': data,
            },
        )

        # Get prediction
        model = get_ml_model()
        result = model.predict(data)

        current_app.logger.info(
            'Prediction successful',
            extra={
                'stress_score': result['stress_score'],
                'risk_level': result['risk_level'],
            },
        )

        # Validate output
        response_schema = StressPredictResponseSchema()
        validated_result = response_schema.dump(result)

        return jsonify(validated_result), 200

    except ValidationError as err:
        current_app.logger.warning(
            f'Validation error: {err.messages}',
            extra={'client_ip': request.remote_addr},
        )
        return jsonify({'error': 'Validation failed', 'details': err.messages}), 400

    except Exception as e:
        current_app.logger.error(
            f'Prediction error: {str(e)}',
            extra={'client_ip': request.remote_addr},
            exc_info=True,
        )
        return jsonify({'error': 'Prediction failed'}), 500
