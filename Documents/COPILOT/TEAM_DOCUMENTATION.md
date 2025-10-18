# Team Documentation: Copilot Log Sharing Infrastructure

## Overview

This documentation provides comprehensive instructions for teams to set up and use the Copilot log-sharing infrastructure across all Perplexity spaces.

---

## 🏗️ Infrastructure Setup

### Prerequisites

- Docker or Kubernetes environment
- Shared file system access across services
- Proper user/group permissions configured
- Node.js environment for Perplexity spaces

### Quick Setup Commands

```bash
# 1. Run the automated setup script
sudo ./setup-log-sharing.sh

# 2. For Docker environments
docker-compose up -d

# 3. For Kubernetes environments
kubectl apply -f k8s/

# 4. Test the setup
test-copilot-logs
```

---

## 📁 Directory Structure

After setup, your log directory structure will be:

```
/var/perplexity/copilot-logs/
├── 2025-10-18.log              # Current day's logs
├── 2025-10-17.log              # Previous day's logs
├── archive/                     # Archived logs (>30 days)
├── monitoring/                  # Monitoring scripts output
└── backup/                      # Backup location
```

---

## 🔧 Environment Configuration

### Copilot Agent Configuration

Add to your `copilot/.env`:
```bash
# Log Directory Configuration
LOG_DIR=/var/perplexity/copilot-logs

# For Docker/Kubernetes
LOG_DIR=/app/logs

# Production Settings
NODE_ENV=production
LOG_LEVEL=info
```

### Perplexity Space Configuration

Add to each space's environment:
```bash
# Shared Log Access
SHARED_COPILOT_LOGS=/shared/copilot-logs
COPILOT_URL=http://copilot-agent:4000
SPACE_NAME=your-space-name

# Thresholds and Limits
ERROR_THRESHOLD=5
LOG_RETENTION_LINES=50
REQUEST_TIMEOUT=30000
```

---

## 🚀 Integration Guide for Perplexity Spaces

### Step 1: Install the Template

Copy the integration template to your space:
```bash
cp perplexity-space-template.js your-space/src/copilot-integration.js
```

### Step 2: Basic Integration

```javascript
import { 
  getRecentCopilotLogs, 
  sendContextAwareRequest,
  checkCopilotHealthWithLogs 
} from './copilot-integration.js';

// Before any Copilot interaction
async function handleUserRequest(userPrompt, userContext) {
  try {
    // Check system health first
    const health = await checkCopilotHealthWithLogs();
    
    if (health.overallStatus === 'unhealthy') {
      return {
        reply: "System is experiencing issues. Please try again later.",
        error: true
      };
    }
    
    // Send context-aware request
    const response = await sendContextAwareRequest(userPrompt, {
      ...userContext,
      user: 'space-user',
      sessionId: 'session-123'
    });
    
    return {
      reply: response.reply,
      requestId: response.requestId,
      systemHealth: health.overallStatus
    };
    
  } catch (error) {
    console.error('Copilot request failed:', error.message);
    return {
      reply: "I'm experiencing technical difficulties. Please try again.",
      error: true
    };
  }
}
```

### Step 3: Advanced Usage

```javascript
// Batch processing example
async function processBulkRequests(requests) {
  return await processBatchRequests(
    requests.map(req => ({
      prompt: req.text,
      context: { user: req.userId, type: 'bulk' }
    })),
    {
      delayMs: 500,        // 500ms between requests
      stopOnError: false   // Continue on individual failures
    }
  );
}

// Real-time monitoring example
setInterval(async () => {
  const { logs, analysis } = getRecentCopilotLogs(10);
  
  if (analysis.errorCount > 3) {
    console.log('⚠️ High error rate detected:', analysis.errorCount);
    // Implement alerting logic here
  }
}, 60000); // Check every minute
```

---

## 📊 Monitoring and Alerting

### Log Metrics to Monitor

1. **Error Rate**: `analysis.errorCount / analysis.totalEntries`
2. **Response Time**: Track request duration
3. **System Health**: Monitor `systemHealth` status
4. **Log Availability**: Ensure logs are accessible

### Setting Up Alerts

```javascript
// Example alerting function
function checkAndAlert(analysis) {
  const alerts = [];
  
  if (analysis.errorCount > 5) {
    alerts.push({
      level: 'critical',
      message: `High error count: ${analysis.errorCount}`,
      action: 'Investigate system logs immediately'
    });
  }
  
  if (analysis.systemHealth === 'unhealthy') {
    alerts.push({
      level: 'warning',
      message: 'System health degraded',
      action: 'Review recent errors and system status'
    });
  }
  
  if (!analysis.available) {
    alerts.push({
      level: 'info',
      message: 'Log analysis unavailable',
      action: 'Check log file permissions and accessibility'
    });
  }
  
  // Send alerts to your monitoring system
  alerts.forEach(alert => sendAlert(alert));
}
```

---

## 🐛 Troubleshooting

### Common Issues

#### 1. "No log file found"
**Cause**: Log directory not accessible or Copilot not writing logs
**Solution**: 
```bash
# Check permissions
ls -la /var/perplexity/copilot-logs/

# Verify Copilot is running and configured
systemctl status copilot-agent
```

#### 2. "Permission denied" when reading logs
**Cause**: User not in correct group or wrong permissions
**Solution**:
```bash
# Add user to copilot group
sudo usermod -a -G perplexity your-username

# Check group membership
groups your-username

# Re-run permissions script
sudo ./setup-log-sharing.sh
```

#### 3. "High error count" alerts
**Cause**: System issues or configuration problems
**Solution**:
```bash
# Check recent errors
tail -100 /var/perplexity/copilot-logs/$(date +%Y-%m-%d).log | grep ERROR

# Review Copilot health
curl http://copilot-agent:4000/health
```

#### 4. Docker volume mounting issues
**Cause**: Volume paths not matching between host and container
**Solution**:
```yaml
# In docker-compose.yml, ensure paths match
volumes:
  - /var/perplexity/copilot-logs:/app/logs        # Copilot writes here
  - /var/perplexity/copilot-logs:/shared/copilot-logs:ro  # Spaces read here
```

### Diagnostic Commands

```bash
# Test log access
test-copilot-logs

# Monitor logs in real-time
tail -f /var/perplexity/copilot-logs/$(date +%Y-%m-%d).log

# Check recent errors
grep ERROR /var/perplexity/copilot-logs/$(date +%Y-%m-%d).log | tail -10

# Verify permissions
ls -la /var/perplexity/copilot-logs/

# Check disk usage
df -h /var/perplexity/copilot-logs/
```

---

## 📋 Team Workflow Checklist

### For Each New Perplexity Space

- [ ] Copy integration template to space codebase
- [ ] Configure environment variables
- [ ] Test log access with `getRecentCopilotLogs()`
- [ ] Implement context-aware request handling
- [ ] Add health checking to space startup
- [ ] Configure monitoring and alerting
- [ ] Document space-specific usage patterns
- [ ] Add space to team monitoring dashboard

### For Operations Team

- [ ] Ensure log directory is properly mounted
- [ ] Monitor disk usage and implement log rotation
- [ ] Set up centralized alerting for high error rates
- [ ] Configure backup and disaster recovery
- [ ] Regular permission audits and updates
- [ ] Performance monitoring and optimization
- [ ] Documentation updates and team training

### For Development Team

- [ ] Follow integration template patterns
- [ ] Include log context in all Copilot requests
- [ ] Implement proper error handling
- [ ] Add request timing and performance metrics
- [ ] Test integration thoroughly before deployment
- [ ] Update space documentation with usage examples

---

## 🔄 Maintenance and Updates

### Regular Tasks

**Daily**:
- Monitor error rates and system health
- Check log accessibility across all spaces
- Review any new error patterns

**Weekly**:
- Analyze log usage patterns and performance
- Update error thresholds based on patterns
- Review and update space configurations

**Monthly**:
- Audit permissions and access controls
- Update integration templates with improvements
- Train new team members on log integration
- Review and optimize log retention policies

### Log Rotation and Cleanup

Logs are automatically rotated daily and compressed. Configure retention:

```bash
# Edit /etc/logrotate.d/copilot-logs
/var/perplexity/copilot-logs/*.log {
    daily
    rotate 30      # Keep 30 days
    compress
    delaycompress
    missingok
    notifempty
    create 644 copilot perplexity
}
```

---

## 📞 Support and Resources

### Getting Help

1. **Check this documentation first**
2. **Run diagnostic commands** from troubleshooting section
3. **Review recent logs** for error patterns
4. **Contact the platform team** with specific error messages

### Useful Resources

- **Integration Template**: `perplexity-space-template.js`
- **Setup Script**: `setup-log-sharing.sh`
- **Health Monitoring**: `test-copilot-logs`
- **Docker Config**: `docker-compose.yml`
- **Kubernetes Config**: `k8s/copilot-deployment.yaml`

### Best Practices Summary

1. ✅ **Always check logs** before sending requests to Copilot
2. ✅ **Include meaningful context** in all requests
3. ✅ **Monitor system health** and respond to degradation
4. ✅ **Handle errors gracefully** with user-friendly messages
5. ✅ **Log all interactions** for audit and debugging
6. ✅ **Test integration thoroughly** in development
7. ✅ **Keep documentation updated** with team changes

---

This completes the comprehensive team documentation for Copilot log sharing infrastructure. Teams now have everything needed to implement, monitor, and maintain context-aware AI interactions across all Perplexity spaces.