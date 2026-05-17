import logging
import sys
from pythonjsonlogger import jsonlogger


def setup_logger(app):
    """Setup structured JSON logging"""

    log_handler = logging.StreamHandler(sys.stdout)

    formatter = jsonlogger.JsonFormatter(
        '%(asctime)s %(levelname)s %(name)s %(message)s %(pathname)s %(lineno)d',
    )

    log_handler.setFormatter(formatter)

    app.logger.addHandler(log_handler)
    app.logger.setLevel(app.config['LOG_LEVEL'])

    # Disable werkzeug default logging
    logging.getLogger('werkzeug').setLevel(logging.WARNING)

    return app.logger
