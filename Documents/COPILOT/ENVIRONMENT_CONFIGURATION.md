# Environment Configuration Guide for Copilot Log Sharing

## Overview

This guide provides standardized environment configurations for all deployment scenarios of the Copilot log-sharing infrastructure.

---

## 🏭 Production Environment

### Copilot Agent (`.env`)

```bash
# AI Service Configuration
COPILOT_API_KEY=your_production_copilot_api_key
OPENAI_API_KEY=your_production_openai_api_key

# Server Configuration
COPILOT_PORT=4000
NODE_ENV=production
LOG_LEVEL=info

# Log Directory Configuration (Production)
LOG_DIR=/var/perplexity/copilot-logs

# Tunnel Configuration
TUNNEL_SUBDOMAIN=prod-copilot-your-org
TUNNEL_URL=https://copilot.your-domain.com

# Slack Integration
SLACK_SIGNING_SECRET=your_production_slack_signing_secret
SLACK_BOT_TOKEN=xoxb-your-production-slack-bot-token

# Google Cloud & Firebase (Production)
GOOGLE_PROJECT_ID=your-production-gcp-project
GOOGLE_APPLICATION_CREDENTIALS=/var/secrets/gcp-prod-key.json
FIREBASE_DATABASE_URL=https://your-prod-project.firebaseio.com
FIREBASE_API_KEY=your_production_firebase_api_key
FIREBASE_AUTH_DOMAIN=your-prod-project.firebaseapp.com
FIREBASE_PROJECT_ID=your-prod-project
FIREBASE_STORAGE_BUCKET=your-prod-project.appspot.com
FIREBASE_MESSAGING_SENDER_ID=your_prod_sender_id
FIREBASE_APP_ID=your_prod_app_id

# Performance & Limits
MAX_REQUEST_SIZE=10mb
REQUEST_TIMEOUT=30000
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX_REQUESTS=100
```

### Perplexity Spaces (Production)

```bash
# Copilot Integration
COPILOT_URL=http://copilot-agent:4000
WEBHOOK_URL=http://webhook-multiplexer:3000
SHARED_COPILOT_LOGS=/shared/copilot-logs

# Space Identity
SPACE_NAME=production-space-name
SPACE_VERSION=1.0.0

# Log Analysis Configuration
ERROR_THRESHOLD=5
LOG_RETENTION_LINES=50
REQUEST_TIMEOUT=30000
BATCH_DELAY_MS=500

# Monitoring & Alerting
ENABLE_MONITORING=true
ALERT_EMAIL=ops-team@your-domain.com
HEALTH_CHECK_INTERVAL_MS=60000
LOG_CHECK_INTERVAL_MS=300000

# Performance Settings
MAX_CONCURRENT_REQUESTS=10
RETRY_ATTEMPTS=3
RETRY_DELAY_MS=1000
```

---

## 🧪 Development Environment

### Copilot Agent (`.env.development`)

```bash
# AI Service Configuration (Development)
COPILOT_API_KEY=your_dev_copilot_api_key
OPENAI_API_KEY=your_dev_openai_api_key

# Server Configuration
COPILOT_PORT=4000
NODE_ENV=development
LOG_LEVEL=debug

# Log Directory Configuration (Development)
LOG_DIR=./logs

# Tunnel Configuration (Development)
TUNNEL_SUBDOMAIN=dev-copilot-your-name
TUNNEL_URL=https://dev-copilot-your-name.ngrok.io

# Slack Integration (Development)
SLACK_SIGNING_SECRET=your_dev_slack_signing_secret
SLACK_BOT_TOKEN=xoxb-your-dev-slack-bot-token

# Google Cloud & Firebase (Development)
GOOGLE_PROJECT_ID=your-dev-gcp-project
GOOGLE_APPLICATION_CREDENTIALS=./dev-gcp-key.json
FIREBASE_DATABASE_URL=https://your-dev-project.firebaseio.com
FIREBASE_API_KEY=your_dev_firebase_api_key
FIREBASE_AUTH_DOMAIN=your-dev-project.firebaseapp.com
FIREBASE_PROJECT_ID=your-dev-project
FIREBASE_STORAGE_BUCKET=your-dev-project.appspot.com
FIREBASE_MESSAGING_SENDER_ID=your_dev_sender_id
FIREBASE_APP_ID=your_dev_app_id

# Development Features
ENABLE_DEBUG_LOGS=true
ENABLE_MOCK_RESPONSES=false
ENABLE_REQUEST_LOGGING=true
```

### Perplexity Spaces (Development)

```bash
# Copilot Integration (Development)
COPILOT_URL=http://localhost:4000
WEBHOOK_URL=http://localhost:3000
SHARED_COPILOT_LOGS=./logs

# Space Identity
SPACE_NAME=dev-space-name
SPACE_VERSION=dev

# Development Settings
ERROR_THRESHOLD=1
LOG_RETENTION_LINES=100
REQUEST_TIMEOUT=10000
BATCH_DELAY_MS=100

# Debug Features
ENABLE_MONITORING=true
ENABLE_DEBUG_OUTPUT=true
LOG_ALL_REQUESTS=true
MOCK_LOG_ANALYSIS=false
```

---

## 🐳 Docker Environment

### Docker Compose Environment

```yaml
# docker-compose.override.yml
version: '3.8'

services:
  copilot-agent:
    environment:
      - LOG_DIR=/app/logs
      - NODE_ENV=production
      - COPILOT_PORT=4000
    volumes:
      - copilot-logs:/app/logs
      - ./copilot/.env.docker:/app/.env

  perplexity-spaces:
    environment:
      - SHARED_COPILOT_LOGS=/shared/copilot-logs
      - COPILOT_URL=http://copilot-agent:4000
    volumes:
      - copilot-logs:/shared/copilot-logs:ro

volumes:
  copilot-logs:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /var/perplexity/copilot-logs
```

### Copilot Agent Docker (`.env.docker`)

```bash
# Docker-specific environment
LOG_DIR=/app/logs
NODE_ENV=production
COPILOT_PORT=4000

# Inherit from docker-compose environment variables
# COPILOT_API_KEY (set via docker-compose secrets)
# SLACK_SIGNING_SECRET (set via docker-compose secrets)
# etc.

# Docker networking
ENABLE_HEALTH_CHECK=true
HEALTH_CHECK_PATH=/health
CONTAINER_TIMEZONE=UTC
```

---

## ☸️ Kubernetes Environment

### ConfigMap (`k8s-configmap.yaml`)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: copilot-config
  namespace: perplexity-copilot
data:
  LOG_DIR: "/app/logs"
  COPILOT_PORT: "4000"
  NODE_ENV: "production"
  SHARED_COPILOT_LOGS: "/shared/copilot-logs"
  ERROR_THRESHOLD: "5"
  LOG_RETENTION_LINES: "50"
  REQUEST_TIMEOUT: "30000"
  ENABLE_MONITORING: "true"
  HEALTH_CHECK_INTERVAL_MS: "60000"
```

### Secrets (`k8s-secrets.yaml`)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: copilot-secrets
  namespace: perplexity-copilot
type: Opaque
stringData:
  COPILOT_API_KEY: "your_k8s_copilot_api_key"
  OPENAI_API_KEY: "your_k8s_openai_api_key"
  SLACK_SIGNING_SECRET: "your_k8s_slack_signing_secret"
  SLACK_BOT_TOKEN: "your_k8s_slack_bot_token"
  FIREBASE_API_KEY: "your_k8s_firebase_api_key"
  GOOGLE_PROJECT_ID: "your_k8s_gcp_project_id"
  GCP_SERVICE_ACCOUNT_JSON: |
    {
      "type": "service_account",
      "project_id": "your-k8s-project",
      ...
    }
```

---

## 🧪 Testing Environment

### Test Configuration (`.env.test`)

```bash
# Test Environment Configuration
NODE_ENV=test
LOG_DIR=./test-logs
COPILOT_PORT=4001

# Mock Services
ENABLE_MOCK_RESPONSES=true
ENABLE_TEST_LOGGING=true
DISABLE_EXTERNAL_CALLS=true

# Test Database
TEST_DB_URL=sqlite://./test.db
CLEAR_TEST_DATA=true

# Reduced Timeouts for Faster Tests
REQUEST_TIMEOUT=5000
HEALTH_CHECK_INTERVAL_MS=10000
ERROR_THRESHOLD=1

# Test-specific Features
ENABLE_DEBUG_LOGS=true
LOG_ALL_REQUESTS=true
SIMULATE_ERRORS=false
MOCK_LOG_ANALYSIS=true
```

---

## 🔧 Environment Validation Script

Create this script to validate your environment setup:

```bash
#!/bin/bash
# validate-environment.sh

ENV_FILE="${1:-.env}"
REQUIRED_VARS=(
    "COPILOT_API_KEY"
    "COPILOT_PORT" 
    "LOG_DIR"
    "NODE_ENV"
)

echo "🔍 Validating environment file: $ENV_FILE"

if [[ ! -f "$ENV_FILE" ]]; then
    echo "❌ Environment file not found: $ENV_FILE"
    exit 1
fi

source "$ENV_FILE"

for var in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!var}" ]]; then
        echo "❌ Missing required variable: $var"
        exit 1
    else
        echo "✅ $var: ${!var}"
    fi
done

# Validate LOG_DIR accessibility
if [[ ! -d "$LOG_DIR" ]]; then
    echo "⚠️  Log directory does not exist: $LOG_DIR"
    echo "   Creating directory..."
    mkdir -p "$LOG_DIR" || {
        echo "❌ Failed to create log directory"
        exit 1
    }
fi

if [[ ! -w "$LOG_DIR" ]]; then
    echo "❌ Log directory is not writable: $LOG_DIR"
    exit 1
fi

echo "✅ Environment validation passed!"
```

---

## 📊 Environment-Specific Features

### Production Features
- Full logging and monitoring
- Rate limiting and security hardening
- Automatic log rotation and cleanup
- Health checks and alerting
- Performance optimization

### Development Features
- Verbose debug logging
- Hot reloading and development tools
- Mock responses for testing
- Reduced security for easier debugging
- Local file system usage

### Testing Features
- Isolated test databases
- Mock external services
- Faster timeouts for quicker tests
- Automatic cleanup after tests
- Deterministic behavior

---

## 🔄 Environment Migration Checklist

### From Development to Production

- [ ] Update all API keys to production values
- [ ] Change LOG_DIR to shared production path
- [ ] Set NODE_ENV to production
- [ ] Enable proper security settings
- [ ] Configure production monitoring
- [ ] Update firewall and network settings
- [ ] Test log sharing across all services
- [ ] Verify backup and recovery procedures

### From Local to Docker

- [ ] Update LOG_DIR to container path (/app/logs)
- [ ] Configure volume mounts for log sharing
- [ ] Update service URLs to container networking
- [ ] Set up proper Docker secrets management
- [ ] Test inter-container communication
- [ ] Verify log accessibility across containers

### From Docker to Kubernetes

- [ ] Convert environment variables to ConfigMaps
- [ ] Move secrets to Kubernetes Secrets
- [ ] Configure PersistentVolumes for log storage
- [ ] Set up proper RBAC and security contexts
- [ ] Configure Ingress for external access
- [ ] Set up monitoring and logging aggregation

---

This completes the comprehensive environment configuration guide for all deployment scenarios!