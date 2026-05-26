from marshmallow import Schema, fields, validate, ValidationError, validates_schema


class StressPredictSchema(Schema):
    """Input validation schema for stress prediction"""

    device_id = fields.String(
        required=True,
        error_messages={'required': 'device_id is required'},
    )

    social_minutes = fields.Integer(
        required=True,
        validate=validate.Range(min=0, max=1440),
        error_messages={'required': 'social_minutes is required'},
    )

    late_night_usage = fields.Boolean(
        required=True,
        error_messages={'required': 'late_night_usage is required'},
    )

    sleep_minutes = fields.Integer(
        required=True,
        validate=validate.Range(min=0, max=960),
        error_messages={'required': 'sleep_minutes is required'},
    )

    doom_scroll_flag = fields.Boolean(
        required=True,
        error_messages={'required': 'doom_scroll_flag is required'},
    )

    pickup_count = fields.Integer(
        required=True,
        validate=validate.Range(min=0, max=500),
        error_messages={'required': 'pickup_count is required'},
    )

    exercise_minutes = fields.Integer(
        required=False,
        validate=validate.Range(min=0, max=480),
        allow_none=True,
    )

    resting_heart_rate = fields.Integer(
        required=False,
        validate=validate.Range(min=40, max=200),
        allow_none=True,
    )

    hrv_score = fields.Float(
        required=False,
        validate=validate.Range(min=0, max=200),
        allow_none=True,
    )

    total_screen_minutes = fields.Integer(
        required=False,
        validate=validate.Range(min=0, max=1440),
        allow_none=True,
    )

    @validates_schema
    def validate_sleep_screen_time(self, data, **kwargs):
        """Ensure sleep + screen time doesn't exceed 24 hours"""
        sleep = data.get('sleep_minutes', 0)
        screen = data.get('total_screen_minutes', 0)

        if sleep + screen > 1440:
            raise ValidationError(
                'Combined sleep and screen time cannot exceed 24 hours'
            )


class StressPredictResponseSchema(Schema):
    """Output schema for stress prediction"""

    stress_score = fields.Integer()
    risk_level = fields.String(validate=validate.OneOf(['low', 'medium', 'high']))
    confidence = fields.Float()
    contextual_message = fields.String()
    model_version = fields.String()
    timestamp = fields.String()

