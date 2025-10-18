# Copilot Integration: Log-Aware Middleware & Team Workflow Instructions

This document outlines the complete log-aware middleware implementation and standardized team workflows for context-driven AI interactions.

***

## 🔧 1. Copilot Agent Implementation

### Middleware Architecture (Already Implemented in `copilot/server.js`)

```javascript
// Helper: read recent log lines
function readRecentLogs(lines = 20) {
  const date = new Date().toISOString().slice(0,10);
  const logDir = process.env.LOG_DIR || path.join(__dirname,'logs');
  const filePath = path.join(logDir, `${date}.log`);
  if (!fs.existsSync(filePath)) return [];
  return fs.readFileSync(filePath,'utf-8')
           .trim()
           .split('\n')
           .slice(-lines)
           .filter(line => line.trim() !== '');
}

// Middleware: attach recent logs to request
app.use('/process', (req, res, next) => {
  const recentLogs = readRecentLogs(20);
  req.recentLogs = recentLogs;
  
  // Extract key metrics from recent logs
  const errorCount = recentLogs.filter(line => line.includes('ERROR')).length;
  const healthChecks = recentLogs.filter(line => line.includes('HEALTH_CHECK')).length;
  const recentRequests = recentLogs.filter(line => line.includes('REQ')).length;
  
  req.logMetrics = {
    totalLines: recentLogs.length,
    errorCount,
    healthChecks,
    recentRequests,
    lastLogTime: recentLogs.length > 0 ? recentLogs[recentLogs.length - 1].substring(0, 24) : null
  };
  
  writeLog(`LOG_CHECK ${recentLogs.length} lines loaded, ${errorCount} errors, ${recentRequests} recent requests`);
  next();
});

// Enhanced /process handler
app.post('/process', async (req, res) => {
  const logContext = `Recent: ${req.logMetrics.totalLines} logs, ${req.logMetrics.errorCount} errors, last: ${req.logMetrics.lastLogTime}`;
  writeLog(`THREAD_START ${logContext} - REQ ${JSON.stringify(req.body)}`);
  
  // Include req.recentLogs in AI prompt context
  // System prompt is enhanced with operational awareness
  // Response includes logMetrics for monitoring
});
```

### Key Features:
- **Automatic Log Analysis**: Every request includes recent operational context
- **Error Detection**: Proactive identification of system issues
- **Metrics Extraction**: Real-time operational health indicators
- **Context Integration**: AI responses informed by system state

***

## 📚 2. Perplexity Spaces Usage Guidelines

### Standard Implementation for All Spaces

Add this **"Copilot Log Reference Requirement"** to each space's documentation:

```markdown
## Copilot Log Reference Requirement

Before sending a new user thread to Copilot, retrieve and analyze the latest logs:

### Step 1: Fetch Recent Logs
```bash
tail -20 /shared/copilot-logs/$(date +%F).log
```

### Step 2: Analyze for Context
- Check for ERROR entries (system issues)
- Review HEALTH_CHECK frequency (system stability)
- Monitor REQ/RES patterns (current load)

### Step 3: Include in Request

#### Node.js Implementation
```javascript
import { execSync } from 'child_process';

async function sendToCopilotwithContext(prompt, userContext = {}) {
  // Fetch recent logs
  const recentLogs = execSync(
    'tail -20 /shared/copilot-logs/$(date +%F).log'
  ).toString().split('\n').filter(line => line.trim());
  
  // Analyze log patterns
  const logAnalysis = {
    errorCount: recentLogs.filter(line => line.includes('ERROR')).length,
    lastActivity: recentLogs[recentLogs.length - 1]?.substring(0, 24)
  };
  
  // Send contextualized request
  const response = await fetch('http://copilot-agent:4000/process', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ 
      prompt, 
      context: {
        ...userContext,
        spaceId: 'your-perplexity-space-name',
        requestId: `pplx-${Date.now()}`
      },
      recentLogs 
    })
  });
  
  const result = await response.json();
  
  // Log interaction for audit
  console.log(`Copilot request: ${logAnalysis.errorCount} recent errors, server metrics:`, result.logMetrics);
  
  return result;
}
```

#### Python Implementation
```python
import subprocess, json, requests
from datetime import datetime

def send_to_copilot_with_context(prompt, user_context=None):
    # Fetch recent logs
    try:
        recent_logs = subprocess.check_output([
            'tail', '-20', f'/shared/copilot-logs/{datetime.now().strftime("%Y-%m-%d")}.log'
        ], text=True).strip().split('\n')
    except:
        recent_logs = []
    
    # Send request with context
    response = requests.post('http://copilot-agent:4000/process', json={
        'prompt': prompt,
        'context': {**(user_context or {}), 'spaceId': 'your-space-name'},
        'recentLogs': recent_logs
    })
    
    return response.json()
```
```

***

## 🏢 3. Team Workflow Improvements

### Infrastructure Setup

#### Log Directory Mounting
```bash
# Docker Compose / Kubernetes
volumes:
  - /app/logs:/shared/copilot-logs  # Mount Copilot logs to shared location
```

#### Centralized Log Access
```bash
# Ensure all Perplexity spaces can access:
/shared/copilot-logs/
├── 2025-10-18.log
├── 2025-10-17.log
└── ...
```

### Monitoring & Analytics

#### 1. Automated Metrics Collection
Parse log entries to track:
- **LOG_CHECK** frequency: System health monitoring
- **THREAD_START** patterns: Request volume analysis  
- **ERROR** entries: System reliability metrics
- **Context usage**: How often logs influence AI responses

#### 2. Dashboard Implementation
```javascript
// Example metrics extraction
const logMetrics = {
  requestVolume: logEntries.filter(e => e.includes('THREAD_START')).length,
  errorRate: logEntries.filter(e => e.includes('ERROR')).length / totalRequests,
  contextUsage: logEntries.filter(e => e.includes('Context:')).length,
  avgResponseTime: calculateAvgFromLogs(logEntries)
};
```

#### 3. Alerting Rules
- **Error Rate > 5%**: Immediate alert to on-call team
- **Log Check Failures**: System health degradation warning
- **High Request Volume**: Auto-scaling trigger
- **Context Misses**: Integration health check

### Sprint Planning Integration

#### Weekly Log Reviews
1. **Error Pattern Analysis**: Identify recurring issues
2. **Performance Trends**: Track response times and throughput
3. **Context Effectiveness**: Measure how logs improve AI responses
4. **Integration Health**: Monitor Perplexity space compliance

#### Continuous Improvement Process
```markdown
## Weekly Copilot Review Checklist

- [ ] Review error patterns and root causes
- [ ] Analyze request volume trends
- [ ] Assess context usage effectiveness
- [ ] Update Perplexity space integration guidelines
- [ ] Plan prompt engineering improvements
- [ ] Schedule infrastructure optimizations
```

***

## 🔍 4. Operational Benefits

### Proactive System Management
- **Early Error Detection**: Issues identified before user impact
- **Context-Aware Responses**: AI informed by real system state
- **Performance Optimization**: Data-driven scaling decisions

### Team Collaboration
- **Standardized Integration**: Consistent approach across all spaces
- **Shared Visibility**: Everyone has access to operational context
- **Data-Driven Decisions**: Log metrics guide development priorities

### Quality Assurance
- **Audit Trail**: Complete record of AI interactions and context
- **Reproducible Issues**: Log context enables better debugging
- **Performance Metrics**: Quantifiable AI response quality

***

## 🚀 5. Implementation Checklist

### For Platform Team:
- [x] Deploy log-aware middleware in Copilot agent
- [x] Set up centralized log directory mounting
- [ ] Configure monitoring dashboards
- [ ] Set up alerting rules
- [ ] Create team training materials

### For Perplexity Space Teams:
- [ ] Update each space's integration to include log checks
- [ ] Test log access and parsing functionality
- [ ] Implement error handling for log unavailability
- [ ] Add space-specific context identifiers
- [ ] Document space-specific usage patterns

### For DevOps Team:
- [ ] Ensure log directory permissions and accessibility
- [ ] Set up log rotation and retention policies
- [ ] Configure backup and disaster recovery
- [ ] Monitor log storage capacity
- [ ] Implement log shipping to analytics platforms

By embedding this middleware and standardizing log access across all Perplexity spaces, Copilot operates with full visibility into recent system state, enabling proactive improvements and stronger team collaboration.

---

**Next Steps**: Roll out to all Perplexity spaces and establish regular monitoring reviews.