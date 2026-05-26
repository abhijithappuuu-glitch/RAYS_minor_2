from flask import Blueprint, request, jsonify, current_app
from app.database import db
from app.models.db_models import UserFeedback
from app.middleware.auth import require_api_key

feedback_bp = Blueprint('feedback', __name__)

@feedback_bp.route('/feedback', methods=['POST'])
@require_api_key
def submit_feedback():
    """
    Endpoint for Ecological Momentary Assessments (Active Learning)
    """
    data = request.json
    device_id = data.get('device_id')
    reported_stress_level = data.get('reported_stress_level')
    context = data.get('context', '')
    
    if not device_id or not reported_stress_level:
        return jsonify({'error': 'device_id and reported_stress_level are required'}), 400
        
    try:
        feedback = UserFeedback(
            device_id=device_id,
            reported_stress_level=int(reported_stress_level),
            context=context
        )
        db.session.add(feedback)
        db.session.commit()
        return jsonify({'message': 'Feedback received successfully'}), 201
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Feedback submission failed: {e}")
        return jsonify({'error': 'Failed to submit feedback'}), 500
