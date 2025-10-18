#!/usr/bin/env bash

# Setup Log Directories for Container Mounting
# Creates required directories for Docker and Kubernetes volume mounting
# Version: 1.0.0

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Directory configuration
COPILOT_LOG_DIR="/var/perplexity/copilot-logs"
PERPLEXITY_SPACES_DIR="${HOME}/Perplexity/spaces"

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Create Copilot logs directory
setup_copilot_logs() {
    log_info "Setting up Copilot logs directory: $COPILOT_LOG_DIR"
    
    if [[ ! -d "$COPILOT_LOG_DIR" ]]; then
        sudo mkdir -p "$COPILOT_LOG_DIR"
        sudo chown "$USER:$(id -gn)" "$COPILOT_LOG_DIR"
        sudo chmod 755 "$COPILOT_LOG_DIR"
        log_success "Created Copilot logs directory"
    else
        log_info "Copilot logs directory already exists"
    fi
    
    # Create sample log files for testing
    cat > "$COPILOT_LOG_DIR/copilot-agent.log" << EOF
# Copilot Agent Log - $(date)
# This is a sample log file for testing container mounts
agent_start=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
status=active
version=1.0.0
EOF
    
    cat > "$COPILOT_LOG_DIR/webhook-multiplexer.log" << EOF
# Webhook Multiplexer Log - $(date)
# Sample webhook events for testing
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
event=webhook_received
status=processed
EOF
    
    log_success "Created sample log files"
}

# Ensure Perplexity spaces directory exists
setup_perplexity_spaces() {
    log_info "Setting up Perplexity spaces directory: $PERPLEXITY_SPACES_DIR"
    
    if [[ ! -d "$PERPLEXITY_SPACES_DIR" ]]; then
        mkdir -p "$PERPLEXITY_SPACES_DIR"
        log_success "Created Perplexity spaces directory"
        
        # Create sample spaces for testing
        local sample_spaces=("general" "research" "001-HUMAN-AI-FRAMEWORK")
        
        for space in "${sample_spaces[@]}"; do
            local space_dir="$PERPLEXITY_SPACES_DIR/$space"
            mkdir -p "$space_dir"
            
            # Create sample objectives file
            cat > "$space_dir/objectives.json" << EOF
{
  "spaceName": "$space",
  "objectives": [
    {
      "id": "sample-objective-1",
      "title": "Sample Objective",
      "description": "This is a sample objective for testing",
      "created": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
      "status": "active"
    }
  ],
  "metadata": {
    "version": "1.0.0",
    "lastUpdated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  }
}
EOF
            
            log_info "Created sample space: $space"
        done
        
        log_success "Created sample spaces for testing"
    else
        log_info "Perplexity spaces directory already exists"
    fi
}

# Verify directory permissions
verify_permissions() {
    log_info "Verifying directory permissions"
    
    # Check Copilot logs
    if [[ -r "$COPILOT_LOG_DIR" ]]; then
        log_success "Copilot logs directory is readable"
    else
        log_warning "Copilot logs directory is not readable"
        return 1
    fi
    
    # Check Perplexity spaces
    if [[ -r "$PERPLEXITY_SPACES_DIR" ]]; then
        log_success "Perplexity spaces directory is readable"
    else
        log_warning "Perplexity spaces directory is not readable"
        return 1
    fi
    
    # List contents for verification
    log_info "Copilot logs contents:"
    ls -la "$COPILOT_LOG_DIR" || true
    
    log_info "Perplexity spaces contents:"
    ls -la "$PERPLEXITY_SPACES_DIR" || true
}

# Show usage information
show_help() {
    cat << EOF
Setup Log Directories for Container Mounting

This script creates the required directories on the host system
for Docker and Kubernetes volume mounting.

Directories created:
  - $COPILOT_LOG_DIR (Copilot logs)
  - $PERPLEXITY_SPACES_DIR (Perplexity spaces)

Usage: $0 [options]

Options:
  --help               Show this help message
  --verify-only        Only verify existing directories
  --copilot-only       Setup only Copilot logs directory
  --spaces-only        Setup only Perplexity spaces directory

Examples:
  $0                   # Setup all directories
  $0 --verify-only     # Verify existing setup
  $0 --copilot-only    # Setup only Copilot logs
EOF
}

# Main function
main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              LOG DIRECTORIES SETUP                           ║"
    echo "║           For Docker/Kubernetes Volume Mounting              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    local verify_only=false
    local copilot_only=false
    local spaces_only=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help)
                show_help
                exit 0
                ;;
            --verify-only)
                verify_only=true
                shift
                ;;
            --copilot-only)
                copilot_only=true
                shift
                ;;
            --spaces-only)
                spaces_only=true
                shift
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    if $verify_only; then
        verify_permissions
        exit 0
    fi
    
    # Setup directories
    if ! $spaces_only; then
        setup_copilot_logs
    fi
    
    if ! $copilot_only; then
        setup_perplexity_spaces
    fi
    
    # Verify setup
    verify_permissions
    
    echo -e "\n${GREEN}🎉 Log directories setup completed!${NC}"
    echo -e "${BLUE}Ready for container mounting with:${NC}"
    echo -e "  • Copilot logs: $COPILOT_LOG_DIR"
    echo -e "  • Perplexity spaces: $PERPLEXITY_SPACES_DIR"
}

# Run main function
main "$@"