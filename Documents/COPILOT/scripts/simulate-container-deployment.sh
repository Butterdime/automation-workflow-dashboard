#!/bin/bash

# HUMAN AI FRAMEWORK Space Simulation
# Simulates container deployment with volume mounting for local testing
# Version: 1.0.0

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
SIMULATION_PORT=4001
PID_FILE="$BASE_DIR/human-ai-framework-space.pid"

# Simulated container paths
SHARED_COPILOT_LOGS="/shared/copilot-logs"
SHARED_PERPLEXITY_SPACES="/shared/perplexity-spaces"

# Host paths (real directories)
HOST_COPILOT_LOGS="/var/perplexity/copilot-logs"
HOST_PERPLEXITY_SPACES="$HOME/Perplexity/spaces"

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_header() {
    echo -e "\n${CYAN}🔍 $1${NC}"
}

# Create simulation environment
setup_simulation() {
    log_header "Setting up HUMAN AI FRAMEWORK Space Simulation"
    
    # Create simulation directories
    mkdir -p "$BASE_DIR/simulation/shared/copilot-logs"
    mkdir -p "$BASE_DIR/simulation/shared/perplexity-spaces"
    mkdir -p "$BASE_DIR/simulation/web"
    
    # Create symbolic links to simulate volume mounts
    if [[ -d "$HOST_COPILOT_LOGS" ]]; then
        ln -sf "$HOST_COPILOT_LOGS"/* "$BASE_DIR/simulation/shared/copilot-logs/" 2>/dev/null || true
        log_success "Linked Copilot logs: $HOST_COPILOT_LOGS -> simulation/shared/copilot-logs"
    else
        log_warning "Copilot logs directory not found: $HOST_COPILOT_LOGS"
    fi
    
    if [[ -d "$HOST_PERPLEXITY_SPACES" ]]; then
        ln -sf "$HOST_PERPLEXITY_SPACES"/* "$BASE_DIR/simulation/shared/perplexity-spaces/" 2>/dev/null || true
        log_success "Linked Perplexity spaces: $HOST_PERPLEXITY_SPACES -> simulation/shared/perplexity-spaces"
    else
        log_warning "Perplexity spaces directory not found: $HOST_PERPLEXITY_SPACES"
    fi
}

# Create web interface
create_web_interface() {
    log_info "Creating web interface for HUMAN AI FRAMEWORK Space"
    
    cat > "$BASE_DIR/simulation/web/index.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>HUMAN AI FRAMEWORK Space - Container Simulation</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
            margin: 0; 
            padding: 20px; 
            background: #f5f5f5;
        }
        .container { 
            max-width: 1200px; 
            margin: 0 auto; 
            background: white; 
            padding: 30px; 
            border-radius: 8px; 
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .status { 
            padding: 15px; 
            background: linear-gradient(135deg, #e8f5e8, #f0f8f0); 
            border-left: 4px solid #4caf50; 
            margin: 20px 0; 
            border-radius: 4px;
        }
        .mount-info { 
            background: #f8f9fa; 
            padding: 15px; 
            font-family: 'Monaco', 'Menlo', monospace; 
            overflow-x: auto; 
            border: 1px solid #dee2e6;
            border-radius: 4px;
            margin: 10px 0;
        }
        .nav-links { 
            display: flex; 
            gap: 10px; 
            margin: 20px 0; 
        }
        .nav-links a { 
            padding: 10px 15px; 
            background: #007bff; 
            color: white; 
            text-decoration: none; 
            border-radius: 4px; 
            transition: background 0.3s;
        }
        .nav-links a:hover { 
            background: #0056b3; 
        }
        .grid { 
            display: grid; 
            grid-template-columns: 1fr 1fr; 
            gap: 20px; 
            margin: 20px 0; 
        }
        .card { 
            padding: 20px; 
            border: 1px solid #dee2e6; 
            border-radius: 8px; 
            background: #fafafa;
        }
        .logs-preview { 
            max-height: 300px; 
            overflow-y: auto; 
            background: #2d3748; 
            color: #e2e8f0; 
            padding: 15px; 
            font-family: monospace; 
            border-radius: 4px;
        }
        h1 { color: #2c3e50; }
        h2 { color: #34495e; border-bottom: 2px solid #3498db; padding-bottom: 5px; }
        .emoji { font-size: 1.2em; }
        .timestamp { color: #6c757d; font-size: 0.9em; }
    </style>
    <script>
        function refreshLogs() {
            fetch('/api/logs')
                .then(response => response.json())
                .then(data => {
                    document.getElementById('logs-content').innerHTML = data.logs || 'No logs available';
                })
                .catch(error => console.error('Error fetching logs:', error));
        }
        
        function refreshSpaces() {
            fetch('/api/spaces')
                .then(response => response.json())
                .then(data => {
                    document.getElementById('spaces-content').innerHTML = JSON.stringify(data, null, 2);
                })
                .catch(error => console.error('Error fetching spaces:', error));
        }
        
        setInterval(refreshLogs, 5000); // Refresh every 5 seconds
    </script>
</head>
<body>
    <div class="container">
        <h1><span class="emoji">🤖</span> HUMAN AI FRAMEWORK Space</h1>
        <p class="timestamp">Container Simulation - Started $(date)</p>
        
        <div class="status">
            <strong>Status:</strong> <span style="color: #4caf50;">●</span> Online and Ready<br>
            <strong>Space Name:</strong> HUMAN-AI-FRAMEWORK<br>
            <strong>Container ID:</strong> human-ai-framework-space (simulated)<br>
            <strong>Port:</strong> $SIMULATION_PORT<br>
            <strong>Environment:</strong> Local Simulation
        </div>
        
        <div class="nav-links">
            <a href="#status">Status</a>
            <a href="#volumes">Volumes</a>
            <a href="#logs">Logs</a>
            <a href="#spaces">Spaces</a>
            <a href="javascript:refreshLogs()">Refresh Logs</a>
            <a href="javascript:refreshSpaces()">Refresh Spaces</a>
        </div>
        
        <h2 id="volumes"><span class="emoji">📂</span> Mounted Volumes</h2>
        <div class="mount-info">
<strong>Volume Mounts (Simulated Container Environment):</strong><br>
<br>
HOST DIRECTORY                          → CONTAINER MOUNT POINT<br>
/var/perplexity/copilot-logs           → /shared/copilot-logs (read-only)<br>
~/Perplexity/spaces                     → /shared/perplexity-spaces (read-only)<br>
./human-ai-framework                    → /app/human-ai-framework (read-write)<br>
./logs                                  → /app/logs (read-write)<br>
./config                                → /app/config (read-only)<br>
<br>
<strong>Simulation Mapping:</strong><br>
./simulation/shared/copilot-logs        ← Simulated /shared/copilot-logs<br>
./simulation/shared/perplexity-spaces   ← Simulated /shared/perplexity-spaces<br>
        </div>
        
        <div class="grid">
            <div class="card">
                <h2 id="logs"><span class="emoji">📄</span> Copilot Logs</h2>
                <div class="logs-preview" id="logs-content">
                    Loading logs...
                </div>
                <button onclick="refreshLogs()" style="margin-top: 10px; padding: 5px 10px;">Refresh Logs</button>
            </div>
            
            <div class="card">
                <h2 id="spaces"><span class="emoji">🌌</span> Perplexity Spaces</h2>
                <div class="logs-preview" id="spaces-content">
                    Loading spaces...
                </div>
                <button onclick="refreshSpaces()" style="margin-top: 10px; padding: 5px 10px;">Refresh Spaces</button>
            </div>
        </div>
        
        <h2 id="status"><span class="emoji">⚙️</span> Service Status</h2>
        <div class="mount-info">
Volume Access Status:<br>
$(if [[ -d "$HOST_COPILOT_LOGS" ]]; then echo "✅ Copilot logs accessible: $HOST_COPILOT_LOGS"; else echo "❌ Copilot logs not found: $HOST_COPILOT_LOGS"; fi)<br>
$(if [[ -d "$HOST_PERPLEXITY_SPACES" ]]; then echo "✅ Perplexity spaces accessible: $HOST_PERPLEXITY_SPACES"; else echo "❌ Perplexity spaces not found: $HOST_PERPLEXITY_SPACES"; fi)<br>
<br>
Container Runtime: Simulated (Local Python HTTP Server)<br>
Port Mapping: localhost:$SIMULATION_PORT → container:4000<br>
Network: host (simulation mode)<br>
Restart Policy: manual<br>
        </div>
        
        <h2><span class="emoji">🚀</span> Deployment Information</h2>
        <p>This simulates the HUMAN AI FRAMEWORK Space container that would be deployed using:</p>
        <div class="mount-info">
<strong>Docker Compose Command:</strong><br>
docker compose up -d human-ai-framework-space<br>
<br>
<strong>Kubernetes Command:</strong><br>
kubectl apply -f k8s/copilot-deployment.yaml<br>
<br>
<strong>Direct Docker Command:</strong><br>
docker run -d --name human-ai-framework-space \\<br>
  -p 4001:4000 \\<br>
  -v /var/perplexity/copilot-logs:/shared/copilot-logs:ro \\<br>
  -v ~/Perplexity/spaces:/shared/perplexity-spaces:ro \\<br>
  -e SPACE_NAME=HUMAN-AI-FRAMEWORK \\<br>
  human-ai-framework:latest
        </div>
        
        <div class="status" style="background: linear-gradient(135deg, #fff3cd, #ffeaa7); border-left-color: #f39c12;">
            <strong>Note:</strong> This is a simulation of the container environment. In production, this would run as a proper Docker container with actual volume mounts providing seamless access to Copilot logs and Perplexity spaces data.
        </div>
    </div>
</body>
</html>
EOF

    log_success "Created web interface at simulation/web/index.html"
}

# Start the simulation service
start_simulation() {
    log_header "Starting HUMAN AI FRAMEWORK Space Simulation"
    
    # Check if already running
    if [[ -f "$PID_FILE" ]] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        log_warning "Service already running (PID: $(cat "$PID_FILE"))"
        return 0
    fi
    
    # Start Python HTTP server
    cd "$BASE_DIR/simulation/web"
    
    log_info "Starting HTTP server on port $SIMULATION_PORT"
    python3 -m http.server $SIMULATION_PORT &
    SERVER_PID=$!
    
    # Save PID
    echo $SERVER_PID > "$PID_FILE"
    
    log_success "HUMAN AI FRAMEWORK Space simulation started"
    log_info "Service running at: http://localhost:$SIMULATION_PORT"
    log_info "PID: $SERVER_PID"
    
    # Show access information
    echo -e "\n${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                  CONTAINER SIMULATION READY                  ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${CYAN}Access the HUMAN AI FRAMEWORK Space at:${NC}"
    echo -e "${GREEN}🌐 http://localhost:$SIMULATION_PORT${NC}"
    echo ""
    echo -e "${CYAN}Simulated Volume Mounts:${NC}"
    echo -e "${GREEN}📂 Copilot Logs: simulation/shared/copilot-logs${NC}"
    echo -e "${GREEN}📂 Perplexity Spaces: simulation/shared/perplexity-spaces${NC}"
    echo ""
    echo -e "${CYAN}Control Commands:${NC}"
    echo -e "${GREEN}Stop: $0 stop${NC}"
    echo -e "${GREEN}Status: $0 status${NC}"
    echo -e "${GREEN}Logs: $0 logs${NC}"
}

# Stop the simulation service
stop_simulation() {
    log_header "Stopping HUMAN AI FRAMEWORK Space Simulation"
    
    if [[ -f "$PID_FILE" ]]; then
        PID=$(cat "$PID_FILE")
        if kill -0 $PID 2>/dev/null; then
            kill $PID
            rm -f "$PID_FILE"
            log_success "Service stopped (PID: $PID)"
        else
            log_warning "Service not running (stale PID file)"
            rm -f "$PID_FILE"
        fi
    else
        log_warning "Service not running (no PID file)"
    fi
}

# Show service status
show_status() {
    log_header "HUMAN AI FRAMEWORK Space Simulation Status"
    
    if [[ -f "$PID_FILE" ]] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        PID=$(cat "$PID_FILE")
        log_success "Service running (PID: $PID)"
        log_info "URL: http://localhost:$SIMULATION_PORT"
        
        # Test connectivity
        if command -v curl &> /dev/null; then
            if curl -s "http://localhost:$SIMULATION_PORT" > /dev/null; then
                log_success "Service responding to HTTP requests"
            else
                log_warning "Service not responding to HTTP requests"
            fi
        fi
    else
        log_warning "Service not running"
    fi
    
    # Show volume status
    log_info "Volume Status:"
    if [[ -d "$HOST_COPILOT_LOGS" ]]; then
        log_success "Copilot logs available: $HOST_COPILOT_LOGS"
    else
        log_warning "Copilot logs not found: $HOST_COPILOT_LOGS"
    fi
    
    if [[ -d "$HOST_PERPLEXITY_SPACES" ]]; then
        log_success "Perplexity spaces available: $HOST_PERPLEXITY_SPACES"
    else
        log_warning "Perplexity spaces not found: $HOST_PERPLEXITY_SPACES"
    fi
}

# Show service logs
show_logs() {
    log_header "HUMAN AI FRAMEWORK Space Simulation Logs"
    
    if [[ -f "$PID_FILE" ]] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        log_info "Service is running, showing simulated container logs..."
        
        echo -e "${CYAN}=== Container Environment Logs ===${NC}"
        echo "Space Name: HUMAN-AI-FRAMEWORK"
        echo "Mount Status:"
        
        if [[ -d "$HOST_COPILOT_LOGS" ]]; then
            echo "✅ /shared/copilot-logs mounted from $HOST_COPILOT_LOGS"
            echo "   Contents:"
            ls -la "$HOST_COPILOT_LOGS" 2>/dev/null || echo "   (no files)"
        else
            echo "❌ /shared/copilot-logs not mounted"
        fi
        
        if [[ -d "$HOST_PERPLEXITY_SPACES" ]]; then
            echo "✅ /shared/perplexity-spaces mounted from $HOST_PERPLEXITY_SPACES"
            echo "   Contents:"
            ls -la "$HOST_PERPLEXITY_SPACES" 2>/dev/null || echo "   (no files)"
        else
            echo "❌ /shared/perplexity-spaces not mounted"
        fi
        
        echo ""
        echo "HTTP Server Log: Access at http://localhost:$SIMULATION_PORT"
    else
        log_warning "Service not running"
    fi
}

# Show help
show_help() {
    cat << EOF
HUMAN AI FRAMEWORK Space Simulation

This script simulates the container deployment with volume mounting
for testing and demonstration purposes.

Usage: $0 [command]

Commands:
  start                Start the simulation service (default)
  stop                 Stop the simulation service
  status               Show service status
  logs                 Show simulated container logs
  help                 Show this help message

Examples:
  $0                   # Start the simulation
  $0 start             # Start the simulation
  $0 stop              # Stop the simulation
  $0 status            # Check if running

The simulation creates a web interface at http://localhost:$SIMULATION_PORT
that demonstrates how the container would access mounted volumes.

Simulated Volume Mounts:
- $HOST_COPILOT_LOGS → /shared/copilot-logs
- $HOST_PERPLEXITY_SPACES → /shared/perplexity-spaces
EOF
}

# Main function
main() {
    local command="${1:-start}"
    
    case $command in
        "start")
            setup_simulation
            create_web_interface
            start_simulation
            ;;
        "stop")
            stop_simulation
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs
            ;;
        "help"|"--help")
            show_help
            ;;
        *)
            echo "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"