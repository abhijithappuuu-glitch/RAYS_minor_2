import re


def sanitize_string(value):
    """Remove potentially dangerous characters from input strings"""
    if not isinstance(value, str):
        return value
    # Strip HTML tags
    clean = re.sub(r'<[^>]+>', '', value)
    # Strip null bytes
    clean = clean.replace('\x00', '')
    return clean.strip()


def validate_positive_int(value, field_name='value'):
    """Validate that a value is a non-negative integer"""
    if not isinstance(value, int) or value < 0:
        raise ValueError(f'{field_name} must be a non-negative integer')
    return value


def validate_range(value, min_val, max_val, field_name='value'):
    """Validate that a numeric value falls within a given range"""
    if value < min_val or value > max_val:
        raise ValueError(f'{field_name} must be between {min_val} and {max_val}')
    return value
