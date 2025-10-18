#!/bin/bash

# CI/CD Pipeline Local Validation Script
# Simulates the GitHub Actions workflow locally for testing

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
NODE_VERSION="18"
COPILOT_PORT="4000"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Status tracking
STEP_COUNT=0
PASSED_STEPS=0
FAILED_STEPS=0

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; ((PASSED_STEPS++)); }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; ((FAILED_STEPS++)); }
log_step() { 
    ((STEP_COUNT++))
    echo -e "\n${CYAN}🔄 Step $STEP_COUNT: $1${NC}"
}

# Cleanup function
cleanup() {
    log_info "Cleaning up background processes..."
    pkill -f "node copilot/server.js" 2>/dev/null || true
    pkill -f "tunnel-setup.js" 2>/dev/null || true
    rm -f copilot.log tunnel.log 2>/dev/null || true
}

# Set trap for cleanup
trap cleanup EXIT

main() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              CI/CD PIPELINE LOCAL VALIDATION                ║"
    echo "║                  Simulating GitHub Actions                  ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    log_info "Project Root: $PROJECT_ROOT"
    log_info "Node Version: $NODE_VERSION"
    log_info "Copilot Port: $COPILOT_PORT"
    log_info "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"

    # ========================================
    # Step 1: Checkout (simulated)
    # ========================================
    log_step "Checkout (simulated)"
    if [[ -d "$PROJECT_ROOT/.git" ]]; then
        log_success "Git repository detected"
    else
        log_warning "Not a git repository"
    fi

    # ========================================
    # Step 2: Setup Node.js
    # ========================================
    log_step "Setup Node.js"
    
    local node_version
    if command -v node &> /dev/null; then
        node_version=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [[ "$node_version" -ge 18 ]]; then
            log_success "Node.js $node_version detected (>= 18)"
        else
            log_error "Node.js version too old: $node_version (need >= 18)"
            return 1
        fi
    else
        log_error "Node.js not found"
        return 1
    fi

    # ========================================
    # Step 3: Setup GCP credentials (simulated)
    # ========================================
    log_step "Setup GCP credentials (simulated)"
    
    if [[ -f "$PROJECT_ROOT/copilot/gcp-key.json" ]]; then
        log_success "GCP key file found"
    elif [[ -n "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]]; then
        log_success "GOOGLE_APPLICATION_CREDENTIALS environment variable set"
    else
        log_warning "GCP credentials not found (using mock for local testing)"
        # Create a mock GCP key for local testing
        mkdir -p "$PROJECT_ROOT/copilot"
        echo '{"type": "service_account", "project_id": "mock-project"}' > "$PROJECT_ROOT/copilot/gcp-key.json"
        log_info "Created mock GCP key for testing"
    fi

    # ========================================
    # Step 4: Install Node dependencies
    # ========================================
    log_step "Install Node dependencies"
    
    cd "$PROJECT_ROOT/copilot"
    
    if [[ -f "package.json" ]]; then
        if npm ci --silent; then
            log_success "Copilot dependencies installed"
        else
            log_error "Failed to install copilot dependencies"
            return 1
        fi
    else
        log_error "copilot/package.json not found"
        return 1
    fi
    
    cd "$PROJECT_ROOT"
    
    if [[ -f "package.json" ]]; then
        if npm ci --silent; then
            log_success "Root dependencies installed"
        else
            log_error "Failed to install root dependencies"
            return 1
        fi
    else
        log_warning "Root package.json not found"
    fi

    # ========================================
    # Step 5: Install Firebase & GCP SDK
    # ========================================
    log_step "Install Firebase & GCP SDK"
    
    cd "$PROJECT_ROOT/copilot"
    
    if npm install firebase @google-cloud/firestore --silent; then
        log_success "Firebase & GCP SDK installed"
    else
        log_error "Failed to install Firebase & GCP SDK"
        return 1
    fi
    
    cd "$PROJECT_ROOT"

    # ========================================
    # Step 6: Setup Python
    # ========================================
    log_step "Setup Python"
    
    local python_cmd=""
    for cmd in python3.14 python3.12 python3.11 python3.10 python3 python; do
        if command -v "$cmd" &> /dev/null; then
            python_cmd="$cmd"
            break
        fi
    done
    
    if [[ -n "$python_cmd" ]]; then
        local python_version
        python_version=$($python_cmd --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1-2)
        log_success "Python $python_version detected"
    else
        log_error "Python not found"
        return 1
    fi

    # ========================================
    # Step 7: Install Python dependencies
    # ========================================
    log_step "Install Python dependencies"
    
    # Check if virtual environment exists
    if [[ -d "$PROJECT_ROOT/copilot/.venv" ]]; then
        log_info "Using existing virtual environment"
        source "$PROJECT_ROOT/copilot/.venv/bin/activate"
    else
        log_info "Virtual environment not found, installing globally"
    fi
    
    if $python_cmd -m pip install jsonschema --quiet 2>/dev/null; then
        log_success "Python dependencies installed"
    else
        log_error "Failed to install Python dependencies"
        return 1
    fi

    # ========================================
    # Step 8: Verify JSON & Backup
    # ========================================
    log_step "Verify JSON & Backup"
    
    if [[ -f "$PROJECT_ROOT/verify_jsons.py" ]]; then
        if $python_cmd "$PROJECT_ROOT/verify_jsons.py"; then
            log_success "JSON validation passed"
        else
            log_error "JSON validation failed"
            return 1
        fi
    else
        log_warning "verify_jsons.py not found, skipping JSON validation"
    fi

    # ========================================
    # Step 9: Start Copilot agent
    # ========================================
    log_step "Start Copilot agent"
    
    # Check if .env file exists
    if [[ ! -f "$PROJECT_ROOT/copilot/.env" ]]; then
        log_warning "Environment file not found, creating minimal .env"
        cat > "$PROJECT_ROOT/copilot/.env" << EOF
COPILOT_API_KEY=test_key
OPENAI_API_KEY=test_key
COPILOT_PORT=$COPILOT_PORT
LOG_DIR=./logs
NODE_ENV=test
EOF
    fi
    
    # Start Copilot agent in background
    cd "$PROJECT_ROOT"
    nohup node copilot/server.js > copilot.log 2>&1 &
    local copilot_pid=$!
    
    log_info "Waiting for Copilot agent to start..."
    sleep 5
    
    # Check if service is running
    if curl -f "http://localhost:$COPILOT_PORT/health" --silent --max-time 10 &>/dev/null; then
        log_success "Copilot agent started successfully"
    else
        log_error "Copilot agent failed to start or health check failed"
        log_info "Copilot log output:"
        tail -10 copilot.log || echo "No log output"
        return 1
    fi

    # ========================================
    # Step 10: Start Tunnel (simulated)
    # ========================================
    log_step "Start Tunnel (simulated)"
    
    if [[ -f "$PROJECT_ROOT/copilot/scripts/tunnel-setup.js" ]]; then
        log_info "Tunnel script found, starting in simulation mode..."
        # Don't actually start tunnel in CI, just validate the script exists
        if node -c "$PROJECT_ROOT/copilot/scripts/tunnel-setup.js" 2>/dev/null; then
            log_success "Tunnel script syntax valid"
        else
            log_error "Tunnel script has syntax errors"
            return 1
        fi
    else
        log_warning "Tunnel setup script not found"
    fi

    # ========================================
    # Step 11: Run Smoke Tests
    # ========================================
    log_step "Run Smoke Tests"
    
    if [[ -f "$PROJECT_ROOT/scripts/smoke.js" ]]; then
        if node "$PROJECT_ROOT/scripts/smoke.js"; then
            log_success "Smoke tests passed"
        else
            log_error "Smoke tests failed"
            return 1
        fi
    else
        log_error "Smoke test script not found"
        return 1
    fi

    # ========================================
    # Step 12: Lint & Typecheck (simulated)
    # ========================================
    log_step "Lint & Typecheck (simulated)"
    
    # Check if lint/typecheck scripts exist in package.json
    if [[ -f "$PROJECT_ROOT/package.json" ]]; then
        if grep -q '"lint"' "$PROJECT_ROOT/package.json"; then
            log_success "Lint script found in package.json"
        else
            log_warning "Lint script not found in package.json"
        fi
        
        if grep -q '"typecheck"' "$PROJECT_ROOT/package.json"; then
            log_success "Typecheck script found in package.json"
        else
            log_warning "Typecheck script not found in package.json"
        fi
    else
        log_warning "Root package.json not found"
    fi

    # ========================================
    # Security Scan Simulation
    # ========================================
    log_step "Security Scan (simulated)"
    
    # Check for .env files
    local env_files
    env_files=$(find "$PROJECT_ROOT" -name "*.env" -not -name ".env.example" 2>/dev/null | wc -l)
    
    if [[ "$env_files" -gt 0 ]]; then
        log_warning "Found $env_files .env files (should be git-ignored)"
    else
        log_success "No committed .env files found"
    fi
    
    # Simulated npm audit
    if command -v npm &> /dev/null; then
        log_info "Running npm audit..."
        npm audit --audit-level=moderate || log_warning "Vulnerabilities found in dependencies"
    fi

    # ========================================
    # Final Summary
    # ========================================
    echo -e "\n${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    PIPELINE SUMMARY                         ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "Total Steps: ${BLUE}$STEP_COUNT${NC}"
    echo -e "Passed Steps: ${GREEN}$PASSED_STEPS${NC}"
    echo -e "Failed Steps: ${RED}$FAILED_STEPS${NC}"
    
    if [[ $FAILED_STEPS -eq 0 ]]; then
        echo -e "\n${GREEN}🎉 CI/CD Pipeline Validation Passed!${NC}"
        echo -e "${GREEN}✅ Ready for GitHub Actions deployment${NC}"
        
        echo -e "\n${BLUE}Deployment Summary:${NC}"
        echo -e "- Branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"
        echo -e "- Commit: $(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
        echo -e "- Time: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
        
        return 0
    else
        echo -e "\n${RED}❌ CI/CD Pipeline Validation Failed${NC}"
        echo -e "${RED}Please fix the failed steps before deployment${NC}"
        return 1
    fi
}

# Help function
show_help() {
    cat << EOF
CI/CD Pipeline Local Validation Script

This script simulates the GitHub Actions workflow locally to validate
that your Copilot integration will build and test successfully.

Usage: $0 [options]

Options:
  --help, -h    Show this help message

Examples:
  $0            Run full pipeline validation
  $0 --help     Show this help

The script will:
1. Validate Node.js and Python setup
2. Install all dependencies
3. Check GCP/Firebase configuration  
4. Start services and run health checks
5. Execute smoke tests
6. Perform security checks
7. Generate deployment summary

Exit codes:
  0 - All validations passed
  1 - One or more validations failed
EOF
}

# Parse arguments
case "${1:-}" in
    --help|-h)
        show_help
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac