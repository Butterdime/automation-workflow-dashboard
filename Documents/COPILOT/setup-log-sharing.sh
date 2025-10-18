#!/bin/bash

# Copilot Log Sharing Setup Script
# This script configures proper permissions and directory structure for sharing Copilot logs with Perplexity spaces

set -e

# Configuration
LOG_DIR="/var/perplexity/copilot-logs"
COPILOT_USER="${COPILOT_USER:-copilot}"
COPILOT_GROUP="${COPILOT_GROUP:-perplexity}"
BACKUP_DIR="/var/perplexity/copilot-logs-backup"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_permissions() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Create user and group for Copilot
setup_user_group() {
    log_info "Setting up user and group for Copilot..."
    
    # Create group if it doesn't exist
    if ! getent group "$COPILOT_GROUP" > /dev/null 2>&1; then
        groupadd "$COPILOT_GROUP"
        log_success "Created group: $COPILOT_GROUP"
    else
        log_info "Group $COPILOT_GROUP already exists"
    fi
    
    # Create user if it doesn't exist
    if ! id "$COPILOT_USER" > /dev/null 2>&1; then
        useradd -r -g "$COPILOT_GROUP" -s /bin/false "$COPILOT_USER"
        log_success "Created user: $COPILOT_USER"
    else
        log_info "User $COPILOT_USER already exists"
    fi
}

# Create log directory structure
setup_directories() {
    log_info "Setting up log directory structure..."
    
    # Create main log directory
    mkdir -p "$LOG_DIR"
    log_success "Created directory: $LOG_DIR"
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    log_success "Created backup directory: $BACKUP_DIR"
    
    # Create subdirectories for organization
    mkdir -p "$LOG_DIR/archive"
    mkdir -p "$LOG_DIR/monitoring"
    log_success "Created subdirectories for organization"
}

# Set proper permissions
set_permissions() {
    log_info "Setting permissions for log directories..."
    
    # Set ownership
    chown -R "$COPILOT_USER:$COPILOT_GROUP" "$LOG_DIR"
    chown -R "$COPILOT_USER:$COPILOT_GROUP" "$BACKUP_DIR"
    
    # Set permissions
    # Copilot agent needs write access, Perplexity spaces need read access
    chmod 755 "$LOG_DIR"
    chmod 755 "$BACKUP_DIR"
    chmod 755 "$LOG_DIR/archive"
    chmod 755 "$LOG_DIR/monitoring"
    
    # Set default permissions for new files
    find "$LOG_DIR" -type f -exec chmod 644 {} \;
    
    log_success "Permissions set correctly"
    log_info "Directory permissions:"
    ls -la "$LOG_DIR"
}

# Setup log rotation
setup_log_rotation() {
    log_info "Setting up log rotation..."
    
    cat > /etc/logrotate.d/copilot-logs << EOF
$LOG_DIR/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 $COPILOT_USER $COPILOT_GROUP
    postrotate
        # Signal any processes that might need to reopen log files
        # Add process restart commands here if needed
        systemctl reload copilot-agent 2>/dev/null || true
    endscript
}
EOF
    
    log_success "Log rotation configured"
}

# Create monitoring script
create_monitoring_script() {
    log_info "Creating log monitoring script..."
    
    cat > /usr/local/bin/copilot-log-monitor << 'EOF'
#!/bin/bash

# Copilot Log Monitoring Script
LOG_DIR="/var/perplexity/copilot-logs"
ALERT_EMAIL="${ALERT_EMAIL:-admin@your-domain.com}"
ERROR_THRESHOLD="${ERROR_THRESHOLD:-10}"

# Check current date log file
CURRENT_LOG="$LOG_DIR/$(date +%Y-%m-%d).log"

if [[ -f "$CURRENT_LOG" ]]; then
    # Count errors in the last hour
    ERROR_COUNT=$(grep "ERROR" "$CURRENT_LOG" | grep "$(date -d '1 hour ago' '+%Y-%m-%dT%H')" | wc -l)
    
    if [[ $ERROR_COUNT -gt $ERROR_THRESHOLD ]]; then
        echo "HIGH ERROR COUNT ALERT: $ERROR_COUNT errors in the last hour" | \
        mail -s "Copilot High Error Rate Alert" "$ALERT_EMAIL" 2>/dev/null || \
        logger "Copilot Alert: High error count ($ERROR_COUNT) in last hour"
    fi
    
    # Check disk usage
    DISK_USAGE=$(df "$LOG_DIR" | awk 'NR==2 {print $5}' | sed 's/%//')
    if [[ $DISK_USAGE -gt 80 ]]; then
        echo "DISK USAGE WARNING: Log directory is $DISK_USAGE% full" | \
        mail -s "Copilot Disk Usage Warning" "$ALERT_EMAIL" 2>/dev/null || \
        logger "Copilot Alert: Log directory disk usage at $DISK_USAGE%"
    fi
fi
EOF
    
    chmod +x /usr/local/bin/copilot-log-monitor
    
    # Add to crontab for hourly monitoring
    (crontab -l 2>/dev/null; echo "0 * * * * /usr/local/bin/copilot-log-monitor") | crontab -
    
    log_success "Log monitoring script created and scheduled"
}

# Create systemd service (if systemd is available)
create_systemd_service() {
    if command -v systemctl > /dev/null 2>&1; then
        log_info "Creating systemd service for Copilot..."
        
        cat > /etc/systemd/system/copilot-agent.service << EOF
[Unit]
Description=Copilot AI Agent
After=network.target
Wants=network.target

[Service]
Type=simple
User=$COPILOT_USER
Group=$COPILOT_GROUP
WorkingDirectory=/opt/copilot
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
Environment=LOG_DIR=$LOG_DIR
Environment=NODE_ENV=production
EnvironmentFile=/opt/copilot/.env

# Security settings
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=$LOG_DIR

[Install]
WantedBy=multi-user.target
EOF
        
        systemctl daemon-reload
        log_success "Systemd service created"
        log_info "Enable with: systemctl enable copilot-agent"
        log_info "Start with: systemctl start copilot-agent"
    else
        log_warning "Systemd not available, skipping service creation"
    fi
}

# Add users to group for log access
add_users_to_group() {
    log_info "Adding users to Copilot group for log access..."
    
    # Add current user to group
    if [[ -n "$SUDO_USER" ]]; then
        usermod -a -G "$COPILOT_GROUP" "$SUDO_USER"
        log_success "Added $SUDO_USER to $COPILOT_GROUP group"
    fi
    
    # Add common service users
    for user in www-data nginx perplexity; do
        if id "$user" > /dev/null 2>&1; then
            usermod -a -G "$COPILOT_GROUP" "$user"
            log_success "Added $user to $COPILOT_GROUP group"
        fi
    done
    
    log_warning "Users may need to log out and back in for group changes to take effect"
}

# Create test script
create_test_script() {
    log_info "Creating test script..."
    
    cat > /usr/local/bin/test-copilot-logs << 'EOF'
#!/bin/bash

LOG_DIR="/var/perplexity/copilot-logs"
TEST_FILE="$LOG_DIR/test-$(date +%s).log"

echo "Testing Copilot log access..."

# Test write access (as copilot user)
if sudo -u copilot touch "$TEST_FILE" 2>/dev/null; then
    echo "✅ Write access: OK"
    sudo -u copilot rm "$TEST_FILE"
else
    echo "❌ Write access: FAILED"
fi

# Test read access
CURRENT_LOG="$LOG_DIR/$(date +%Y-%m-%d).log"
if [[ -f "$CURRENT_LOG" ]] && [[ -r "$CURRENT_LOG" ]]; then
    echo "✅ Read access: OK"
    echo "   Log file size: $(du -h "$CURRENT_LOG" | cut -f1)"
    echo "   Last modified: $(stat -c %y "$CURRENT_LOG")"
else
    echo "⚠️  Read access: No current log file found"
fi

# Test directory permissions
echo "📁 Directory permissions:"
ls -la "$LOG_DIR"
EOF
    
    chmod +x /usr/local/bin/test-copilot-logs
    log_success "Test script created at /usr/local/bin/test-copilot-logs"
}

# Main execution
main() {
    log_info "Starting Copilot log sharing setup..."
    echo "========================================"
    
    check_permissions
    setup_user_group
    setup_directories
    set_permissions
    setup_log_rotation
    create_monitoring_script
    create_systemd_service
    add_users_to_group
    create_test_script
    
    echo "========================================"
    log_success "Setup completed successfully!"
    echo
    log_info "Next steps:"
    echo "  1. Update your Copilot configuration to use LOG_DIR=$LOG_DIR"
    echo "  2. Start the Copilot agent service"
    echo "  3. Run 'test-copilot-logs' to verify setup"
    echo "  4. Configure your Perplexity spaces to read from $LOG_DIR"
    echo
    log_info "Useful commands:"
    echo "  - Test setup: test-copilot-logs"
    echo "  - Monitor logs: tail -f $LOG_DIR/\$(date +%Y-%m-%d).log"
    echo "  - Check service: systemctl status copilot-agent"
    echo "  - View log rotation: cat /etc/logrotate.d/copilot-logs"
}

# Run main function
main "$@"