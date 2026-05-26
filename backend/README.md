# RAYS — Backend ML API

Production-grade Flask ML backend for the **RAYS** stress detection & wellness app.

## Overview

This backend provides an optional cloud-based stress prediction API that complements
the on-device analysis in the RAYS Flutter app. It uses a **Random Forest classifier**
trained on behavioral + fitness features to predict stress levels (low / medium / high).

## Architecture

- **Flask 3.0** REST API with blueprints
- **scikit-learn** Random Forest stress predictor (8 features, 3-class output)
- **Marshmallow** schema validation
- **Flask-Limiter** rate limiting (Redis-backed in production)
- **Prometheus** metrics exporter
- **Gunicorn** WSGI server
- **Docker Compose** multi-container deployment (API + Redis)

## Quick Start (Local)

```bash
# Create virtual environment
python -m venv venv
venv\Scripts\activate        # Windows
# source venv/bin/activate   # macOS/Linux

# Install dependencies
pip install -r requirements.txt

# Copy environment config
copy .env.example .env       # Windows
# cp .env.example .env       # macOS/Linux

# (Optional) Train & export model
python ml_training/train_model.py

# Run development server
python wsgi.py
```

The API will start at `http://localhost:5000`.

## Docker Deployment

```bash
# Build and start
docker-compose build
docker-compose up -d

# View logs
docker-compose logs -f api

# Stop
docker-compose down
```

The API will be available at `http://localhost:8000`.

## API Endpoints

### `POST /api/v1/predict`

Predict stress level from behavioral + fitness data.

**Headers:**
| Header | Required | Description |
|--------|----------|-------------|
| `X-API-Key` | Yes | Valid API key |
| `Content-Type` | Yes | `application/json` |

**Request Body:**
```json
{
  "social_minutes": 120,
  "late_night_usage": true,
  "sleep_minutes": 360,
  "doom_scroll_flag": false,
  "pickup_count": 80,
  "exercise_minutes": 30,
  "resting_heart_rate": 72,
  "total_screen_minutes": 300
}
```

| Field | Type | Description |
|-------|------|-------------|
| `social_minutes` | int | Minutes spent on social media today |
| `late_night_usage` | bool | Phone used between 12–4 AM |
| `sleep_minutes` | int | Total sleep duration in minutes |
| `doom_scroll_flag` | bool | Extended uninterrupted social scrolling detected |
| `pickup_count` | int | Number of phone unlocks today |
| `exercise_minutes` | int | Minutes of physical activity |
| `resting_heart_rate` | int | BPM from Google Fit / Health Connect |
| `total_screen_minutes` | int | Total screen-on time in minutes |

**Response:**
```json
{
  "stress_score": 52,
  "risk_level": "medium",
  "confidence": 0.847,
  "model_version": "1.0.0",
  "timestamp": "2026-02-22T10:30:00"
}
```

| Field | Description |
|-------|-------------|
| `stress_score` | 0–100 composite score |
| `risk_level` | `"low"` / `"medium"` / `"high"` |
| `confidence` | Model prediction confidence (0–1) |

### `GET /api/v1/health`

Health check — no auth required. Returns `200 OK`.

### `GET /api/v1/ready`

Kubernetes readiness probe — confirms the ML model is loaded and ready.

## ML Model Training

The training script generates synthetic behavioral data and trains a Random Forest:

```bash
python ml_training/train_model.py
```

**Features used (8):**
| Feature | Description |
|---------|-------------|
| `social_minutes` | Social media screen time |
| `late_night_usage` | Binary: phone used 12–4 AM |
| `sleep_minutes` | Total sleep duration |
| `doom_scroll_flag` | Binary: doom-scrolling detected |
| `pickup_count` | Phone unlock frequency |
| `exercise_minutes` | Physical activity duration |
| `resting_heart_rate` | Heart rate from wearable/fit |
| `total_screen_minutes` | Total screen-on time |

**Output:** `app/models/stress_predictor.pkl`

The model achieves ~85%+ cross-validation accuracy on synthetic data.

## Running Tests

```bash
pytest tests/ -v --cov=app
```

## Project Structure

```
rakshak-backend/
├── app/
│   ├── __init__.py          # Flask app factory
│   ├── config.py            # Environment configs
│   ├── models/
│   │   └── ml_model.py      # StressPredictor class
│   ├── middleware/
│   │   ├── auth.py          # API key & HMAC auth
│   │   ├── rate_limiter.py  # In-memory fallback limiter
│   │   └── security.py      # Response security headers
│   ├── routes/
│   │   ├── predict.py       # /predict endpoint
│   │   └── health.py        # /health & /ready
│   ├── schemas/
│   │   └── stress_schema.py # Marshmallow schemas
│   └── utils/
│       ├── logger.py        # JSON structured logging
│       └── validators.py    # Input sanitization
├── ml_training/
│   ├── train_model.py       # Model training script
│   └── sample_data.csv      # Generated on first run
├── tests/
│   ├── test_predict.py      # API endpoint tests
│   └── test_security.py     # Security header & auth tests
├── Dockerfile
├── docker-compose.yml
├── gunicorn_config.py
├── wsgi.py
├── requirements.txt
└── .env.example
```

## How RAYS Uses This Backend

The RAYS Flutter app can operate **fully offline** using its on-device stress analysis engine.
When network is available, it optionally sends anonymized behavioral features to this API
for a second opinion via the trained Random Forest model. The app then blends both scores.

```
┌──────────────────────┐       ┌─────────────────────┐
│   RAYS Flutter App   │       │   RAYS Backend API   │
│                      │       │                      │
│ ┌──────────────────┐ │  POST │ ┌──────────────────┐ │
│ │ On-device Engine │ │──────>│ │ Random Forest ML │ │
│ │ (always works)   │ │<──────│ │ (enhanced score)  │ │
│ └──────────────────┘ │  JSON │ └──────────────────┘ │
└──────────────────────┘       └─────────────────────┘
```

## Production Checklist

- [ ] Replace `SECRET_KEY` with a cryptographically secure value
- [ ] Generate strong API keys and store in environment variables
- [ ] Enable HTTPS with SSL certificates
- [ ] Point `RATELIMIT_STORAGE_URL` to production Redis
- [ ] Configure Prometheus + Grafana monitoring
- [ ] Set up log aggregation (ELK / CloudWatch)
- [ ] Enable firewall rules
- [ ] Configure auto-scaling
