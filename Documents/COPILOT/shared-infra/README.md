# Shared Infrastructure for Perplexity Spaces
# Universal technical foundations for all spaces

This directory contains standardized infrastructure components that can be deployed across all Perplexity spaces while maintaining content isolation and security.

## 🏗️ Infrastructure Components

### Core Services
- **`server.js`** - Standardized Copilot agent server with health monitoring
- **`tunnel-setup.js`** - Universal ngrok tunnel configuration
- **`smoke.js`** - Comprehensive testing suite for all spaces
- **`weekly-compilation.py`** - HUMAN AI FRAMEWORK exclusive data compilation

### Configuration
- **`ci-cd.yml`** - Reusable GitHub Actions workflow
- **`.env.template`** - Universal environment configuration template

## 🚀 Deployment

### Automatic Deployment (Recommended)
```bash
# Deploy to all spaces automatically
./deploy-infra.sh

# Deploy to specific spaces
./deploy-infra.sh space1 space2 space3
```

### Manual Deployment
```bash
# Copy shared infrastructure to target space
rsync -av --exclude='human-ai-framework/' shared-infra/ /path/to/target/space/

# Configure environment
cp shared-infra/.env.template /path/to/target/space/.env
# Edit .env with space-specific values

# Install dependencies
cd /path/to/target/space
npm install express node-fetch ngrok

# Start services
node server.js
```

## 📋 Features

### Universal Copilot Server
- Health monitoring endpoints
- Space-specific configuration
- Consistent API across all spaces
- Performance metrics collection
- Graceful error handling

### Tunnel Management
- Automated ngrok tunnel setup
- Space-specific subdomains
- Connection monitoring and recovery
- Environment variable updates
- Process lifecycle management

### Testing Suite
- Comprehensive smoke tests
- Health check validation
- Integration testing
- Performance benchmarks
- Audit logging

### CI/CD Pipeline
- Automated building and testing
- Security vulnerability scanning
- Multi-environment support
- Health check verification
- Deployment automation

## 🔒 Security & Isolation

### Space Isolation
- Each space receives isolated copy of infrastructure
- No shared state between spaces
- Independent configuration management
- Separate logging and monitoring

### Content Protection
- HUMAN AI FRAMEWORK content remains exclusive
- Automatic exclusion patterns prevent cross-space contamination
- Security validation and audit logging
- Access control enforcement

### Security Features
- Environment variable validation
- File system permission checks
- Tunnel connection security
- API authentication ready
- Audit trail maintenance

## 📊 Monitoring & Logging

### Health Monitoring
- `/health` endpoint for basic health checks
- `/metrics` endpoint for performance data
- `/space` endpoint for space-specific information
- Uptime and availability tracking

### Logging
- Structured logging with timestamps
- Space identification in all logs
- Error tracking and aggregation
- Performance metrics collection
- Audit trail for security events

## 🛠️ Configuration

### Environment Variables
All spaces use the same configuration template but with space-specific values:

```bash
# Required
SPACE_NAME=your-space-name
COPILOT_PORT=4000
WEBHOOK_PORT=3000

# Optional but recommended
OPENAI_API_KEY=your-key
NGROK_AUTH_TOKEN=your-token
SLACK_BOT_TOKEN=your-token
```

### Space-Specific Customization
- Copy `.env.template` to `.env` in each space
- Modify `SPACE_NAME` to match the space identifier
- Configure integrations as needed
- Maintain consistent port assignments

## 🔄 Weekly Compilation (HUMAN AI FRAMEWORK Only)

### Exclusive Features
- Automated weekly data collection
- Security validation and audit logging
- Content isolation and protection
- Compliance reporting
- Retention policy management

### Exclusivity Enforcement
- Only runs in HUMAN AI FRAMEWORK space
- Access validation prevents unauthorized usage
- Content exclusivity verification
- Cross-space contamination prevention

## 📚 Usage Examples

### Start Copilot Agent
```bash
cd /path/to/space
node server.js
```

### Setup Tunnel
```bash
node tunnel-setup.js
```

### Run Tests
```bash
node smoke.js
```

### Run Weekly Compilation (HUMAN AI FRAMEWORK only)
```bash
python3 weekly-compilation.py
```

## 🔧 Troubleshooting

### Common Issues
1. **Port conflicts**: Adjust COPILOT_PORT and WEBHOOK_PORT
2. **Tunnel failures**: Verify NGROK_AUTH_TOKEN
3. **Permission errors**: Check file system permissions
4. **Space isolation**: Ensure SPACE_NAME is correctly set

### Debug Mode
```bash
# Enable debug logging
export LOG_LEVEL=DEBUG
node server.js
```

### Health Checks
```bash
# Check service health
curl http://localhost:4000/health

# View metrics
curl http://localhost:4000/metrics

# Check space info
curl http://localhost:4000/space
```

## 🎯 Best Practices

### Deployment
- Always backup existing configurations before deploying
- Test in development environment first
- Monitor logs during deployment
- Verify health checks after deployment
- Maintain space isolation

### Configuration Management
- Use environment variables for all configuration
- Never hardcode sensitive values
- Keep .env files secure and untracked
- Document space-specific customizations
- Regular configuration audits

### Security
- Regularly rotate API keys and tokens
- Monitor access logs for anomalies
- Validate environment configurations
- Maintain audit trails
- Follow principle of least privilege

## 📈 Metrics & Analytics

### Performance Tracking
- Response time monitoring
- Error rate tracking
- Resource utilization
- Tunnel connectivity status
- Health check results

### Usage Analytics
- Request volume per space
- Feature utilization
- Integration effectiveness
- Performance benchmarks
- Compliance metrics

---

**Note**: This shared infrastructure maintains strict isolation between spaces while providing consistent technical foundations. HUMAN AI FRAMEWORK exclusive content is protected and never shared across spaces.