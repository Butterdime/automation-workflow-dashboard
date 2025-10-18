# Container Log Mounting Configuration

This document describes the log mounting configuration for Docker and Kubernetes deployments of the HUMAN AI FRAMEWORK space.

## Overview

The system provides shared access to Copilot logs and Perplexity spaces data through container volume mounting. This enables the weekly compilation system to access data from both local and mounted sources.

## Directory Structure

### Host Directories
- `/var/perplexity/copilot-logs` - Shared Copilot logs directory
- `~/Perplexity/spaces` - Perplexity spaces directory

### Container Mount Points
- `/shared/copilot-logs` - Read-only mounted Copilot logs
- `/shared/perplexity-spaces` - Read-only mounted Perplexity spaces

## Docker Compose Configuration

The `docker-compose.yml` includes a dedicated service for the HUMAN AI FRAMEWORK space:

```yaml
services:
  human-ai-framework-space:
    build: .
    container_name: human-ai-framework
    volumes:
      - /var/perplexity/copilot-logs:/shared/copilot-logs:ro
      - ~/Perplexity/spaces:/shared/perplexity-spaces:ro
    environment:
      - SPACE_NAME=HUMAN-AI-FRAMEWORK
      - LOG_LEVEL=info
    restart: unless-stopped
```

## Kubernetes Configuration

The `k8s/copilot-deployment.yaml` includes hostPath volumes for log access:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: human-ai-framework-space
spec:
  template:
    spec:
      containers:
      - name: human-ai-framework
        volumeMounts:
        - name: copilot-logs
          mountPath: /shared/copilot-logs
          readOnly: true
        - name: perplexity-spaces
          mountPath: /shared/perplexity-spaces
          readOnly: true
      volumes:
      - name: copilot-logs
        hostPath:
          path: /var/perplexity/copilot-logs
          type: Directory
      - name: perplexity-spaces
        hostPath:
          path: /home/user/Perplexity/spaces
          type: Directory
```

## Setup Instructions

### 1. Create Host Directories

Run the setup script to create required directories:

```bash
# Create all directories
./scripts/setup-log-directories.sh

# Verify setup
./scripts/setup-log-directories.sh --verify-only

# Create only Copilot logs directory
./scripts/setup-log-directories.sh --copilot-only
```

### 2. Deploy with Docker Compose

```bash
# Start the HUMAN AI FRAMEWORK space
docker-compose up -d human-ai-framework-space

# Check logs
docker-compose logs -f human-ai-framework-space
```

### 3. Deploy with Kubernetes

```bash
# Apply the deployment
kubectl apply -f k8s/copilot-deployment.yaml

# Check pod status
kubectl get pods -l app=human-ai-framework-space

# Check logs
kubectl logs -l app=human-ai-framework-space -f
```

## Weekly Compilation Integration

The `weekly-compilation.py` script automatically detects mounted directories:

### Copilot Logs Collection
1. Checks `/shared/copilot-logs` first (mounted)
2. Falls back to local `logs/` directory
3. Supports multiple log patterns:
   - `copilot-*.log`
   - `webhook-*.log`
   - `agent-*.log`

### Objectives Synchronization
1. Checks `/shared/perplexity-spaces` first (mounted)
2. Falls back to local `~/Perplexity/spaces`
3. Injects `spaceName` into all objectives files

## File Access Patterns

### Code Example - Log Collection
```python
def _collect_copilot_logs(self) -> Dict[str, Any]:
    """Collect Copilot logs from mounted or local directories"""
    
    # Check for mounted shared logs first
    shared_logs_base = Path("/shared/copilot-logs")
    local_logs_base = self.base_dir / "logs"
    
    logs_base = shared_logs_base if shared_logs_base.exists() else local_logs_base
    
    # ... collection logic
```

### Code Example - Objectives Sync
```python
def _synchronize_objectives(self) -> Dict[str, Any]:
    """Synchronize objectives from mounted or local Perplexity spaces"""
    
    # Check for mounted shared spaces first
    shared_spaces_base = Path("/shared/perplexity-spaces")
    local_spaces_base = Path.home() / "Perplexity" / "spaces"
    
    spaces_base = shared_spaces_base if shared_spaces_base.exists() else local_spaces_base
    
    # ... synchronization logic
```

## Security Considerations

### Read-Only Access
- All mounted volumes are read-only (`:ro`)
- Prevents container from modifying host data
- Ensures data integrity and security

### Directory Permissions
- Host directories have appropriate user permissions
- Container runs with non-root user when possible
- Log directories are accessible to container user

### Volume Isolation
- Each space has isolated volume mounts
- HUMAN AI FRAMEWORK space has exclusive access to specific directories
- No cross-space data leakage

## Troubleshooting

### Common Issues

1. **Directory Not Found**
   ```bash
   # Check if directories exist
   ls -la /var/perplexity/copilot-logs
   ls -la ~/Perplexity/spaces
   
   # Run setup script
   ./scripts/setup-log-directories.sh
   ```

2. **Permission Denied**
   ```bash
   # Check permissions
   ls -la /var/perplexity/copilot-logs
   
   # Fix permissions
   sudo chown $USER:$(id -gn) /var/perplexity/copilot-logs
   ```

3. **Container Mount Issues**
   ```bash
   # Check Docker mounts
   docker inspect human-ai-framework | grep -A 10 "Mounts"
   
   # Check Kubernetes mounts
   kubectl describe pod -l app=human-ai-framework-space
   ```

### Verification Commands

```bash
# Test Docker mount
docker-compose exec human-ai-framework-space ls -la /shared/

# Test Kubernetes mount
kubectl exec -it deployment/human-ai-framework-space -- ls -la /shared/

# Check weekly compilation with mounts
docker-compose exec human-ai-framework-space python3 weekly-compilation.py --dry-run
```

## Benefits

1. **Centralized Log Access** - All spaces can access shared Copilot logs
2. **Data Consistency** - Single source of truth for Perplexity spaces
3. **Scalability** - Easy to add new spaces with same mount configuration
4. **Flexibility** - Automatic fallback to local directories when mounts unavailable
5. **Security** - Read-only access prevents accidental data modification

## Maintenance

### Regular Tasks
- Monitor log directory disk usage
- Rotate logs to prevent disk full
- Update mount paths if directory structure changes
- Verify container access periodically

### Backup Considerations
- Host directories should be included in backup strategy
- Container data is ephemeral, mounts provide persistence
- Consider backup of both source and mount points

This configuration provides robust, secure access to shared logs and space data while maintaining the flexibility to run in various deployment environments.