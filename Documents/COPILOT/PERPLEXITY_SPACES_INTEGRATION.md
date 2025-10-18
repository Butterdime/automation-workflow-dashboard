# Perplexity Spaces Integration Guide

## Copilot Log Reference Requirement

Before sending any new user thread to the Copilot agent, retrieve and examine the most recent log entries to ensure context-aware processing.

### 🔍 Pre-Thread Log Check Process

1. **Fetch the last 20 log lines** from the shared logs directory:
   ```bash
   tail -20 /shared/copilot-logs/$(date +%F).log
   ```

2. **Review for recent errors or context** that might affect the new thread:
   - Look for ERROR entries that might indicate system issues
   - Check for recent HEALTH_CHECK entries to verify system status
   - Identify recent REQ/RES patterns to understand current load

3. **Record the log-check** in your application context by including the log snippet in the request metadata.

### 📋 Implementation Example

#### JavaScript/Node.js Implementation
```javascript
const { execSync } = require('child_process');

async function sendToCopilotwithLogContext(prompt, userContext = {}) {
  // Step 1: Read recent logs
  const recentLogs = execSync('tail -20 /shared/copilot-logs/$(date +%F).log')
    .toString()
    .split('\n')
    .filter(line => line.trim() !== '');
  
  // Step 2: Analyze log context
  const logAnalysis = {
    errorCount: recentLogs.filter(line => line.includes('ERROR')).length,
    healthChecks: recentLogs.filter(line => line.includes('HEALTH_CHECK')).length,
    recentRequests: recentLogs.filter(line => line.includes('REQ')).length,
    lastActivity: recentLogs.length > 0 ? recentLogs[recentLogs.length - 1].substring(0, 24) : null
  };
  
  // Step 3: Send request with log context
  const response = await fetch('http://copilot-agent:4000/process', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ 
      prompt, 
      context: {
        ...userContext,
        perplexitySpace: 'your-space-name',
        requestId: `pplx-${Date.now()}`
      },
      recentLogs: recentLogs.slice(-10) // Send last 10 log entries
    })
  });
  
  const result = await response.json();
  
  // Step 4: Log the interaction for audit trail
  console.log(`Copilot request completed. Log context: ${JSON.stringify(logAnalysis)}`);
  console.log(`Server metrics: ${JSON.stringify(result.logMetrics)}`);
  
  return result;
}
```

#### Python Implementation
```python
import subprocess
import json
import requests
from datetime import datetime

def send_to_copilot_with_log_context(prompt, user_context=None):
    if user_context is None:
        user_context = {}
    
    # Step 1: Read recent logs
    try:
        recent_logs = subprocess.check_output(
            ['tail', '-20', f'/shared/copilot-logs/{datetime.now().strftime("%Y-%m-%d")}.log'],
            text=True
        ).strip().split('\n')
        recent_logs = [line for line in recent_logs if line.strip()]
    except subprocess.CalledProcessError:
        recent_logs = []
    
    # Step 2: Analyze log context
    log_analysis = {
        'error_count': len([line for line in recent_logs if 'ERROR' in line]),
        'health_checks': len([line for line in recent_logs if 'HEALTH_CHECK' in line]),
        'recent_requests': len([line for line in recent_logs if 'REQ' in line]),
        'last_activity': recent_logs[-1][:24] if recent_logs else None
    }
    
    # Step 3: Send request with log context
    payload = {
        'prompt': prompt,
        'context': {
            **user_context,
            'perplexity_space': 'your-space-name',
            'request_id': f'pplx-{int(datetime.now().timestamp() * 1000)}'
        },
        'recentLogs': recent_logs[-10:]  # Send last 10 log entries
    }
    
    response = requests.post(
        'http://copilot-agent:4000/process',
        headers={'Content-Type': 'application/json'},
        json=payload
    )
    
    result = response.json()
    
    # Step 4: Log the interaction
    print(f"Copilot request completed. Log context: {json.dumps(log_analysis)}")
    print(f"Server metrics: {json.dumps(result.get('logMetrics', {}))}")
    
    return result
```

### 🚦 Best Practices

1. **Always Check Logs First**: Never bypass the log-check step, as it provides crucial operational context.

2. **Handle Log Unavailability**: If logs are not accessible, include this in your request context so Copilot knows it's operating without recent operational insight.

3. **Include Space Identifier**: Always identify which Perplexity space is making the request for better traceability.

4. **Monitor Response Metrics**: Use the returned `logMetrics` to understand system health and adjust your request patterns accordingly.

5. **Implement Retry Logic**: If `errorCount` is high, consider implementing exponential backoff or alerting mechanisms.

### 📊 Understanding Log Metrics

The Copilot agent returns these metrics with each response:

```json
{
  "logMetrics": {
    "totalLines": 20,
    "errorCount": 0,
    "healthChecks": 5,
    "recentRequests": 12,
    "lastLogTime": "2025-10-18T09:15:30.123Z"
  },
  "reply": "Your AI response here",
  "contextUsed": true
}
```

- **totalLines**: Number of recent log entries analyzed
- **errorCount**: Critical errors in recent activity (alerts if > 0)
- **healthChecks**: System health verification requests
- **recentRequests**: Processing load indicator
- **lastLogTime**: Most recent system activity timestamp

### 🔧 Troubleshooting

**Problem**: Log files not accessible
**Solution**: Ensure your Perplexity space has read access to `/shared/copilot-logs/` or adjust the path accordingly.

**Problem**: High error count in logs
**Solution**: Review error patterns, potentially delay requests, and alert administrators.

**Problem**: No recent activity in logs
**Solution**: Verify Copilot agent is running and logging properly.

---

This practice ensures that Copilot's decision-making is informed by the latest operational context, improving reliability and enabling proactive workflow enhancements.