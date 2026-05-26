# RAYS Backend - Deployment Guide

This guide covers deploying the RAYS backend in production environments.

## Prerequisites

- Docker & Docker Compose (for containerized deployment)
- Python 3.10+ (for local development)
- PostgreSQL 16+ (for database)
- Redis 7+ (for caching and rate limiting)
- Kubernetes 1.24+ (for K8s deployment)
- kubectl (for K8s management)

## Quick Start (Docker Compose)

### 1. Prepare Environment

```bash
cd backend
cp .env.example.production .env
# Edit .env with your production values
nano .env
```

**Required variables:**
```
FLASK_ENV=production
SECRET_KEY=your-secure-secret-key-min-32-chars
VALID_API_KEYS=your-api-key-1,your-api-key-2
DATABASE_URL=postgresql://user:password@postgres:5432/rays_db
REDIS_URL=redis://:password@redis:6379/0
```

### 2. Start Services

```bash
# Start all services (API, DB, Redis, Monitoring)
docker-compose -f docker-compose.prod.yml up -d

# Verify health
docker-compose -f docker-compose.prod.yml ps

# Check logs
docker-compose -f docker-compose.prod.yml logs -f api
```

### 3. Initialize Database

```bash
# Run migrations
docker-compose -f docker-compose.prod.yml exec api \
  python manage_migrations.py upgrade

# Verify
docker-compose -f docker-compose.prod.yml exec postgres \
  psql -U rays -d rays_db -c "\dt"
```

### 4. Verify Deployment

```bash
# Health check
curl -H "X-API-Key: your-api-key" http://localhost:8000/api/v1/health

# Test prediction
curl -X POST http://localhost:8000/api/v1/predict \
  -H "X-API-Key: your-api-key" \
  -H "Content-Type: application/json" \
  -d '{
    "device_id": "test-device",
    "social_minutes": 120,
    "late_night_usage": true,
    "sleep_minutes": 360,
    "doom_scroll_flag": false,
    "pickup_count": 80
  }'

# Access API documentation
open http://localhost:8000/apidocs
```

## Kubernetes Deployment

### 1. Create Namespace and Secrets

```bash
kubectl apply -f k8s/deployment.yaml
```

### 2. Configure Secrets

```bash
kubectl create secret generic rays-secrets \
  --from-literal=SECRET_KEY=your-production-key \
  --from-literal=VALID_API_KEYS=key1,key2 \
  -n rays

# Or use kustomize/helm for sensitive data management
```

### 3. Deploy

```bash
kubectl apply -f k8s/
kubectl get deployments -n rays
kubectl get pods -n rays
```

### 4. Monitor Deployment

```bash
# Watch rollout
kubectl rollout status deployment/rays-api -n rays

# Check pod logs
kubectl logs -f deployment/rays-api -n rays

# Port forward
kubectl port-forward svc/rays-api-service 8000:80 -n rays
```

### 5. Scale

```bash
# Manual scaling
kubectl scale deployment rays-api --replicas=5 -n rays

# Auto-scaling (via HPA)
kubectl get hpa -n rays
```

## Local Development

### 1. Setup Virtual Environment

```bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
# or
venv\Scripts\activate  # Windows
```

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

### 3. Configure Development Environment

```bash
cp .env.example .env
# Update with local development values
```

### 4. Run Locally

```bash
# Development server
python wsgi.py

# Or with Flask CLI
export FLASK_APP=wsgi.py
flask run --host=0.0.0.0 --port=5000
```

### 5. Run Tests

```bash
pytest tests/ -v --cov=app
```

## Database Migrations

### Create New Migration

```bash
python manage_migrations.py init  # First time only
# Make model changes...
python manage_migrations.py upgrade
```

### Upgrade Database

```bash
python manage_migrations.py upgrade
```

### Rollback

```bash
python manage_migrations.py downgrade
```

### View History

```bash
python manage_migrations.py history
```

## Monitoring & Logging

### Prometheus Metrics

Metrics are available at: `http://api:8000/metrics`

Key metrics:
- `flask_http_request_total` - Total HTTP requests
- `flask_http_request_duration_seconds` - Request duration
- `stress_predictions_total` - Total predictions made
- `stress_prediction_errors` - Prediction errors

### Grafana Dashboards

1. Access Grafana: `http://localhost:3000` (default: admin/admin)
2. Add Prometheus data source: `http://prometheus:9090`
3. Import pre-built dashboards or create custom ones

### Logging

Logs are in JSON format for easy parsing:

```bash
# View API logs
docker-compose -f docker-compose.prod.yml logs api | jq

# Parse specific fields
docker-compose -f docker-compose.prod.yml logs api | jq '.levelname, .message'
```

## Security Checklist

- [ ] Set strong `SECRET_KEY` (min 32 chars, random)
- [ ] Rotate API keys regularly
- [ ] Enable HTTPS/SSL in production
- [ ] Use strong database passwords
- [ ] Enable Redis password protection
- [ ] Restrict CORS origins
- [ ] Enable firewall rules
- [ ] Monitor error logs for attacks
- [ ] Set up automated backups
- [ ] Test incident response procedures

## Troubleshooting

### API Not Responding

```bash
# Check container status
docker-compose -f docker-compose.prod.yml ps api

# View logs
docker-compose -f docker-compose.prod.yml logs api

# Test connectivity
curl http://localhost:8000/api/v1/health
```

### Database Connection Issues

```bash
# Check if DB is running
docker-compose -f docker-compose.prod.yml ps postgres

# Test connection
psql -h localhost -U rays -d rays_db
```

### High Memory Usage

```bash
# Check resource limits
docker stats

# Adjust in docker-compose.prod.yml
# Or in Kubernetes HPA settings
```

### Model Loading Failures

```bash
# Check model file exists
docker-compose -f docker-compose.prod.yml exec api ls -la app/models/

# Run model training
docker-compose -f docker-compose.prod.yml exec api python ml_training/train_model.py
```

## Backup & Recovery

### Database Backup

```bash
# Backup
docker-compose -f docker-compose.prod.yml exec postgres pg_dump -U rays rays_db > backup.sql

# Restore
docker-compose -f docker-compose.prod.yml exec -T postgres psql -U rays rays_db < backup.sql
```

### Volume Backup

```bash
# Docker volumes
docker run --rm -v rays_postgres_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/postgres-backup.tar.gz -C /data .
```

## Performance Tuning

### Database Tuning

```sql
-- Analyze query performance
EXPLAIN ANALYZE
SELECT * FROM user_telemetry WHERE device_id = 'test' AND timestamp > NOW() - INTERVAL '30 days';

-- Add indexes if needed
CREATE INDEX idx_telemetry_device_date 
ON user_telemetry(device_id, timestamp DESC);
```

### Application Tuning

```python
# In config.py
SQLALCHEMY_POOL_SIZE = 20  # Increase for more connections
SQLALCHEMY_MAX_OVERFLOW = 40  # Allow overflow
SQLALCHEMY_POOL_RECYCLE = 3600  # Recycle connections
```

### Redis Tuning

```bash
# Monitor Redis
redis-cli INFO stats
redis-cli INFO memory
```

## Maintenance Windows

Schedule regular maintenance:

```bash
# Weekly updates
0 2 * * 0 docker-compose -f docker-compose.prod.yml pull && docker-compose -f docker-compose.prod.yml up -d

# Database optimization
0 3 * * 0 docker-compose -f docker-compose.prod.yml exec postgres vacuumdb -U rays rays_db
```

## Support & Documentation

- API Documentation: `http://api-domain/apidocs`
- GitHub: https://github.com/abhijithappuuu-glitch/RAYS_minor_2
- Issues: Submit on GitHub or contact support@rays.local

---

**Last Updated**: May 25, 2026
**Version**: 3.0.0
