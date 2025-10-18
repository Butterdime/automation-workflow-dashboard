#!/bin/bash

# Copilot Log Sharing Infrastructure - Deployment Status & Checklist
# Version: 1.0.0
# Usage: ./deployment-status.sh [environment]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT="${1:-development}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# Status tracking
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# Helper functions
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; ((PASSED_CHECKS++)); }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; ((WARNING_CHECKS++)); }
log_error() { echo -e "${RED}❌ $1${NC}"; ((FAILED_CHECKS++)); }
log_header() { echo -e "\n${PURPLE}🔍 $1${NC}"; }

check_file() {
    local file_path="$1"
    local description="$2"
    ((TOTAL_CHECKS++))
    
    if [[ -f "$file_path" ]]; then
        log_success "$description: $file_path"
        return 0
    else
        log_error "$description: $file_path (missing)"
        return 1
    fi
}

check_directory() {
    local dir_path="$1" 
    local description="$2"
    ((TOTAL_CHECKS++))
    
    if [[ -d "$dir_path" ]]; then
        log_success "$description: $dir_path"
        return 0
    else
        log_error "$description: $dir_path (missing)"
        return 1
    fi
}

check_env_var() {
    local var_name="$1"
    local description="$2"
    ((TOTAL_CHECKS++))
    
    if [[ -n "${!var_name:-}" ]]; then
        log_success "$description: $var_name is set"
        return 0
    else
        log_error "$description: $var_name is not set"
        return 1
    fi
}

check_command() {
    local cmd="$1"
    local description="$2"
    ((TOTAL_CHECKS++))
    
    if command -v "$cmd" &> /dev/null; then
        log_success "$description: $cmd available"
        return 0
    else
        log_error "$description: $cmd not found"
        return 1
    fi
}

check_port() {
    local port="$1"
    local description="$2"
    ((TOTAL_CHECKS++))
    
    if nc -z localhost "$port" 2>/dev/null; then
        log_success "$description: Port $port is accessible"
        return 0
    else
        log_warning "$description: Port $port is not accessible (service may be down)"
        return 1
    fi
}

check_permissions() {
    local path="$1"
    local description="$2"
    local required_perms="$3"
    ((TOTAL_CHECKS++))
    
    if [[ -e "$path" ]]; then
        local actual_perms
        actual_perms=$(stat -f "%A" "$path" 2>/dev/null || stat -c "%a" "$path" 2>/dev/null)
        
        if [[ "$actual_perms" -ge "$required_perms" ]]; then
            log_success "$description: $path has proper permissions ($actual_perms)"
            return 0
        else
            log_error "$description: $path has insufficient permissions ($actual_perms, needs $required_perms)"
            return 1
        fi
    else
        log_error "$description: $path does not exist"
        return 1
    fi
}

# Main deployment status check
main() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║             COPILOT LOG SHARING DEPLOYMENT STATUS           ║"
    echo "║                        Version 1.0.0                        ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    log_info "Environment: $ENVIRONMENT"
    log_info "Project Root: $PROJECT_ROOT"
    log_info "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"

    # ========================================
    # Core Infrastructure Files
    # ========================================
    log_header "Core Infrastructure Files"
    
    check_file "$PROJECT_ROOT/package.json" "Main package.json"
    check_file "$PROJECT_ROOT/webhook-multiplexer.js" "Webhook multiplexer"
    check_file "$PROJECT_ROOT/README.md" "Project README"
    check_file "$PROJECT_ROOT/start.sh" "Start script"

    # ========================================
    # Copilot Agent Files  
    # ========================================
    log_header "Copilot Agent Files"
    
    check_directory "$PROJECT_ROOT/copilot" "Copilot directory"
    check_file "$PROJECT_ROOT/copilot/package.json" "Copilot package.json"
    check_file "$PROJECT_ROOT/copilot/server.js" "Copilot server"
    check_file "$PROJECT_ROOT/copilot/config.json" "Copilot config"
    
    # Environment files
    case "$ENVIRONMENT" in
        "production")
            check_file "$PROJECT_ROOT/copilot/.env" "Production environment file"
            ;;
        "development")
            check_file "$PROJECT_ROOT/copilot/.env.development" "Development environment file"
            ;;
        "docker")
            check_file "$PROJECT_ROOT/copilot/.env.docker" "Docker environment file"
            ;;
        "test")
            check_file "$PROJECT_ROOT/copilot/.env.test" "Test environment file"
            ;;
        *)
            check_file "$PROJECT_ROOT/copilot/.env" "Default environment file"
            ;;
    esac

    # ========================================
    # Scripts and Utilities
    # ========================================
    log_header "Scripts and Utilities"
    
    check_directory "$PROJECT_ROOT/scripts" "Scripts directory"
    check_file "$PROJECT_ROOT/scripts/tunnel-setup.js" "Tunnel setup script"
    check_file "$PROJECT_ROOT/scripts/smoke.js" "Smoke test script"
    check_file "$PROJECT_ROOT/setup-log-sharing.sh" "Log sharing setup"
    check_permissions "$PROJECT_ROOT/setup-log-sharing.sh" "Setup script permissions" "755"

    # ========================================
    # Configuration Files
    # ========================================
    log_header "Configuration Files"
    
    check_directory "$PROJECT_ROOT/config" "Config directory"
    check_file "$PROJECT_ROOT/config/copilot-schema.json" "Copilot JSON schema"
    check_file "$PROJECT_ROOT/verify_jsons.py" "JSON verification script"

    # ========================================
    # Docker Configuration
    # ========================================
    log_header "Docker Configuration"
    
    check_file "$PROJECT_ROOT/docker-compose.yml" "Docker Compose file"
    check_file "$PROJECT_ROOT/Dockerfile" "Main Dockerfile"
    check_file "$PROJECT_ROOT/copilot/Dockerfile" "Copilot Dockerfile"

    # ========================================
    # Kubernetes Configuration
    # ========================================
    log_header "Kubernetes Configuration"
    
    check_directory "$PROJECT_ROOT/k8s" "Kubernetes directory"
    check_file "$PROJECT_ROOT/k8s/namespace.yaml" "K8s namespace"
    check_file "$PROJECT_ROOT/k8s/copilot-deployment.yaml" "K8s deployment"
    check_file "$PROJECT_ROOT/k8s/copilot-service.yaml" "K8s service"
    check_file "$PROJECT_ROOT/k8s/persistent-volume.yaml" "K8s persistent volume"
    check_file "$PROJECT_ROOT/k8s/ingress.yaml" "K8s ingress"

    # ========================================
    # CI/CD Configuration
    # ========================================
    log_header "CI/CD Configuration"
    
    check_directory "$PROJECT_ROOT/.github" "GitHub directory"
    check_directory "$PROJECT_ROOT/.github/workflows" "GitHub workflows"
    check_file "$PROJECT_ROOT/.github/workflows/copilot-integration.yml" "GitHub Actions workflow"

    # ========================================
    # Documentation
    # ========================================
    log_header "Documentation"
    
    check_file "$PROJECT_ROOT/TEAM_DOCUMENTATION.md" "Team documentation"
    check_file "$PROJECT_ROOT/ENVIRONMENT_CONFIGURATION.md" "Environment configuration guide"
    check_file "$PROJECT_ROOT/perplexity-space-template.js" "Perplexity integration template"

    # ========================================
    # Log Directory Structure
    # ========================================
    log_header "Log Directory Structure"
    
    # Load environment to check LOG_DIR
    local env_file
    case "$ENVIRONMENT" in
        "production") env_file="$PROJECT_ROOT/copilot/.env" ;;
        "development") env_file="$PROJECT_ROOT/copilot/.env.development" ;;
        "docker") env_file="$PROJECT_ROOT/copilot/.env.docker" ;;
        "test") env_file="$PROJECT_ROOT/copilot/.env.test" ;;
        *) env_file="$PROJECT_ROOT/copilot/.env" ;;
    esac
    
    if [[ -f "$env_file" ]]; then
        # Source the environment file safely
        while IFS='=' read -r key value; do
            if [[ "$key" =~ ^LOG_DIR$ ]]; then
                export LOG_DIR="$value"
                break
            fi
        done < <(grep -v '^#' "$env_file" | grep -v '^$')
        
        if [[ -n "${LOG_DIR:-}" ]]; then
            # Remove quotes if present
            LOG_DIR=$(echo "$LOG_DIR" | tr -d '"'"'"'')
            
            if [[ "$LOG_DIR" == "./logs" ]]; then
                LOG_DIR="$PROJECT_ROOT/logs"
            fi
            
            check_directory "$LOG_DIR" "Log directory"
            check_permissions "$LOG_DIR" "Log directory permissions" "755"
            
            # Check for log files if directory exists
            if [[ -d "$LOG_DIR" ]]; then
                local log_count
                log_count=$(find "$LOG_DIR" -name "*.log" -o -name "*.json" 2>/dev/null | wc -l)
                if [[ "$log_count" -gt 0 ]]; then
                    log_success "Log files found: $log_count files"
                else
                    log_warning "No log files found in $LOG_DIR (may be expected for new installations)"
                fi
            fi
        else
            log_warning "LOG_DIR not defined in environment file"
        fi
    else
        log_warning "Environment file not found: $env_file"
    fi

    # ========================================
    # System Dependencies  
    # ========================================
    log_header "System Dependencies"
    
    check_command "node" "Node.js"
    check_command "npm" "NPM"
    check_command "git" "Git"
    check_command "curl" "cURL"
    
    if [[ "$ENVIRONMENT" == "docker" ]]; then
        check_command "docker" "Docker"
        check_command "docker-compose" "Docker Compose"
    fi
    
    if [[ "$ENVIRONMENT" == "kubernetes" ]]; then
        check_command "kubectl" "Kubectl"
        check_command "helm" "Helm (optional)"
    fi

    # ========================================
    # Node.js Dependencies
    # ========================================
    log_header "Node.js Dependencies"
    
    if [[ -f "$PROJECT_ROOT/package.json" ]]; then
        local node_modules="$PROJECT_ROOT/node_modules"
        check_directory "$node_modules" "Main node_modules"
    fi
    
    if [[ -f "$PROJECT_ROOT/copilot/package.json" ]]; then
        local copilot_modules="$PROJECT_ROOT/copilot/node_modules"
        check_directory "$copilot_modules" "Copilot node_modules"
    fi

    # ========================================
    # Service Health Checks (if running)
    # ========================================
    log_header "Service Health Checks"
    
    # Load COPILOT_PORT from environment
    local copilot_port=4000
    if [[ -f "$env_file" ]]; then
        while IFS='=' read -r key value; do
            if [[ "$key" =~ ^COPILOT_PORT$ ]]; then
                copilot_port=$(echo "$value" | tr -d '"'"'"'')
                break
            fi
        done < <(grep -v '^#' "$env_file" | grep -v '^$')
    fi
    
    check_port "$copilot_port" "Copilot Agent Service"
    check_port "3000" "Webhook Multiplexer Service"
    
    # Health endpoint checks (if services are running)
    if nc -z localhost "$copilot_port" 2>/dev/null; then
        ((TOTAL_CHECKS++))
        if curl -s "http://localhost:$copilot_port/health" &>/dev/null; then
            log_success "Copilot health endpoint responding"
        else
            log_warning "Copilot service running but health endpoint not responding"
        fi
    fi

    # ========================================
    # Environment-Specific Checks
    # ========================================
    log_header "Environment-Specific Checks ($ENVIRONMENT)"
    
    case "$ENVIRONMENT" in
        "production")
            # Production-specific checks
            log_info "Checking production-specific requirements..."
            
            # Check for systemd service files (if applicable)
            if [[ -f "/etc/systemd/system/copilot-agent.service" ]]; then
                log_success "Systemd service file exists"
            else
                log_warning "Systemd service file not found (manual deployment?)"
            fi
            
            # Check log rotation
            if [[ -f "/etc/logrotate.d/copilot" ]]; then
                log_success "Log rotation configuration exists"
            else
                log_warning "Log rotation not configured"
            fi
            ;;
            
        "development")
            # Development-specific checks
            log_info "Checking development-specific requirements..."
            
            check_command "ngrok" "Ngrok (for tunnel)"
            check_file "$HOME/.ngrok2/ngrok.yml" "Ngrok configuration (optional)"
            ;;
            
        "docker")
            # Docker-specific checks
            log_info "Checking Docker-specific requirements..."
            
            # Check if Docker is running
            ((TOTAL_CHECKS++))
            if docker info &>/dev/null; then
                log_success "Docker daemon is running"
            else
                log_error "Docker daemon is not running"
            fi
            
            # Check for Docker images
            ((TOTAL_CHECKS++))
            if docker images | grep -q "copilot"; then
                log_success "Copilot Docker images found"
            else
                log_warning "Copilot Docker images not built yet"
            fi
            ;;
            
        "kubernetes")
            # Kubernetes-specific checks
            log_info "Checking Kubernetes-specific requirements..."
            
            # Check kubectl connection
            ((TOTAL_CHECKS++))
            if kubectl cluster-info &>/dev/null; then
                log_success "Kubectl connected to cluster"
            else
                log_error "Kubectl not connected to cluster"
            fi
            
            # Check namespace
            ((TOTAL_CHECKS++))
            if kubectl get namespace perplexity-copilot &>/dev/null; then
                log_success "Kubernetes namespace exists"
            else
                log_warning "Kubernetes namespace not created yet"
            fi
            ;;
    esac

    # ========================================
    # Security Checks
    # ========================================
    log_header "Security Checks"
    
    # Check for sensitive files with proper permissions
    if [[ -f "$env_file" ]]; then
        check_permissions "$env_file" "Environment file permissions" "600"
        
        # Check for sensitive data exposure
        ((TOTAL_CHECKS++))
        if grep -q "your_.*_api_key\|example\|placeholder" "$env_file" 2>/dev/null; then
            log_error "Environment file contains placeholder values"
        else
            log_success "Environment file appears to have real values"
        fi
    fi
    
    # Check for any .env files in git
    ((TOTAL_CHECKS++))
    if git check-ignore "$env_file" &>/dev/null || grep -q "\.env" "$PROJECT_ROOT/.gitignore" 2>/dev/null; then
        log_success "Environment files properly ignored by git"
    else
        log_warning "Environment files may not be properly git-ignored"
    fi

    # ========================================
    # Final Summary
    # ========================================
    echo -e "\n${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                        SUMMARY REPORT                       ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "Total Checks: ${BLUE}$TOTAL_CHECKS${NC}"
    echo -e "Passed: ${GREEN}$PASSED_CHECKS${NC}"
    echo -e "Warnings: ${YELLOW}$WARNING_CHECKS${NC}"
    echo -e "Failed: ${RED}$FAILED_CHECKS${NC}"
    
    local success_rate=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
    
    echo -e "\nSuccess Rate: ${BLUE}$success_rate%${NC}"
    
    if [[ $FAILED_CHECKS -eq 0 ]]; then
        if [[ $WARNING_CHECKS -eq 0 ]]; then
            echo -e "\n${GREEN}🎉 All checks passed! Deployment is ready.${NC}"
            exit 0
        else
            echo -e "\n${YELLOW}✅ Deployment ready with warnings. Review warnings above.${NC}"
            exit 0
        fi
    else
        echo -e "\n${RED}❌ Deployment has issues. Please address failed checks above.${NC}"
        
        echo -e "\n${YELLOW}Quick Fix Commands:${NC}"
        echo "• Install dependencies: npm install && cd copilot && npm install"
        echo "• Create directories: mkdir -p logs config k8s scripts"
        echo "• Fix permissions: chmod 755 setup-log-sharing.sh"
        echo "• Copy environment: cp copilot/.env.example copilot/.env"
        
        exit 1
    fi
}

# Help function
show_help() {
    cat << EOF
Copilot Log Sharing Infrastructure - Deployment Status Checker

Usage: $0 [environment]

Environments:
  production    Check production deployment (default)
  development   Check development setup
  docker        Check Docker deployment
  kubernetes    Check Kubernetes deployment  
  test          Check test environment

Examples:
  $0                    # Check production environment
  $0 development        # Check development setup
  $0 docker            # Check Docker deployment
  $0 --help            # Show this help

This script validates the complete Copilot log-sharing infrastructure
including files, permissions, dependencies, and service health.
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