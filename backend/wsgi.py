import os
from dotenv import load_dotenv

# Load .env before importing the app so all os.getenv() calls in config.py
# pick up the correct values (SECRET_KEY, VALID_API_KEYS, etc.)
load_dotenv(os.path.join(os.path.dirname(__file__), '.env'))

from app import create_app

env = os.getenv('FLASK_ENV', 'production')
app = create_app(env)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
