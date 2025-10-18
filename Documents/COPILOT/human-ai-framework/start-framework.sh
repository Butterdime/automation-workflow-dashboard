#!/bin/bash
set -e

echo "Starting HUMAN AI FRAMEWORK Space..."
echo "Space Name: ${SPACE_NAME:-HUMAN-AI-FRAMEWORK}"
echo "Mounted Copilot Logs: ${SHARED_COPILOT_LOGS:-/shared/copilot-logs}"
echo "Mounted Perplexity Spaces: ${SHARED_PERPLEXITY_SPACES:-/shared/perplexity-spaces}"

# Check mounted volumes
if [ -d "${SHARED_COPILOT_LOGS:-/shared/copilot-logs}" ]; then
    echo "✅ Copilot logs mounted at: ${SHARED_COPILOT_LOGS:-/shared/copilot-logs}"
    ls -la "${SHARED_COPILOT_LOGS:-/shared/copilot-logs}" || true
else
    echo "⚠️  Copilot logs not mounted"
fi

if [ -d "${SHARED_PERPLEXITY_SPACES:-/shared/perplexity-spaces}" ]; then
    echo "✅ Perplexity spaces mounted at: ${SHARED_PERPLEXITY_SPACES:-/shared/perplexity-spaces}"
    ls -la "${SHARED_PERPLEXITY_SPACES:-/shared/perplexity-spaces}" || true
else
    echo "⚠️  Perplexity spaces not mounted"
fi

# Create a simple web server response
mkdir -p /app/web
cat > /app/web/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>HUMAN AI FRAMEWORK Space</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .status { padding: 10px; background: #e8f5e8; border: 1px solid #4caf50; margin: 10px 0; }
        .logs { background: #f5f5f5; padding: 10px; font-family: monospace; overflow-x: auto; }
    </style>
</head>
<body>
    <h1>🤖 HUMAN AI FRAMEWORK Space</h1>
    <div class="status">
        <strong>Status:</strong> Online and Ready<br>
        <strong>Space Name:</strong> HUMAN-AI-FRAMEWORK<br>
        <strong>Container ID:</strong> human-ai-framework-space<br>
        <strong>Port:</strong> 4000
    </div>
    
    <h2>📂 Mounted Volumes</h2>
    <div class="logs">
        <strong>Copilot Logs:</strong> /shared/copilot-logs (read-only)<br>
        <strong>Perplexity Spaces:</strong> /shared/perplexity-spaces (read-only)<br>
        <strong>Framework Data:</strong> /app/human-ai-framework (read-write)
    </div>
    
    <h2>🔗 Available Services</h2>
    <ul>
        <li><a href="/health">Health Check</a></li>
        <li><a href="/logs">View Logs</a></li>
        <li><a href="/spaces">Browse Spaces</a></li>
    </ul>
    
    <p><em>Last updated: $(date)</em></p>
</body>
</html>
EOF

echo "HUMAN AI FRAMEWORK Space is running on port 4000"
echo "Health check available at http://localhost:4000"
echo "Web interface available at http://localhost:4000"

# Start the HTTP server
cd /app/web
python3 -m http.server 4000