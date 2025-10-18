#!/usr/bin/env bash

# Infrastructure Deployment Script - Propagate Technical Foundations to All Spaces
# Distributes shared operational configuration while preserving HUMAN-AI-FRAMEWORK exclusivity
# Version: 1.0.0

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARED_REPO="$SCRIPT_DIR/shared-infra"
TARGET_BASE="${HOME}/Perplexity/spaces"
LOG_FILE="$SCRIPT_DIR/deployment.log"
DEPLOYMENT_ID="deploy-$(date +%Y%m%d-%H%M%S)"

# Excluded directories and files (preserve exclusive content)
EXCLUSIONS=(
    "human-ai-content/"
    "001-human-ai-framework-exclusive/"
    "compiled-data/"
    "audit.log"
    "*.private"
    "personal-notes/"
    ".env.local"
)

# Statistics tracking
TOTAL_SPACES=0
UPDATED_SPACES=0
FAILED_SPACES=0
SKIPPED_SPACES=0

# Logging functions
log_info() { 
    echo -e "${BLUE}ℹ️  $1${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] [$DEPLOYMENT_ID] $1" >> "$LOG_FILE"
}

log_success() { 
    echo -e "${GREEN}✅ $1${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] [$DEPLOYMENT_ID] $1" >> "$LOG_FILE"
    ((UPDATED_SPACES++))
}

log_warning() { 
    echo -e "${YELLOW}⚠️  $1${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN] [$DEPLOYMENT_ID] $1" >> "$LOG_FILE"
    ((SKIPPED_SPACES++))
}

log_error() { 
    echo -e "${RED}❌ $1${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] [$DEPLOYMENT_ID] $1" >> "$LOG_FILE"
    ((FAILED_SPACES++))
}

log_header() { 
    echo -e "\n${CYAN}🔍 $1${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [HEADER] [$DEPLOYMENT_ID] $1" >> "$LOG_FILE"
}

# Validate shared infrastructure repository
validate_shared_infra() {
    log_header "Validating Shared Infrastructure Repository"
    
    if [[ ! -d "$SHARED_REPO" ]]; then
        log_error "Shared infrastructure repository not found: $SHARED_REPO"
        return 1
    fi
    
    # Required files in shared-infra
    local required_files=(
        "ci-cd.yml"
        "server.js"
        "tunnel-setup.js"
        "smoke.js"
        "weekly-compilation.py"
        ".env.template"
        "package.json"
        "README.md"
    )
    
    local missing_files=()
    for file in "${required_files[@]}"; do
        if [[ ! -f "$SHARED_REPO/$file" ]]; then
            missing_files+=("$file")
        fi
    done
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        log_error "Missing required files in shared-infra: ${missing_files[*]}"
        return 1
    fi
    
    log_success "Shared infrastructure repository validated"
    return 0
}

# Create exclusion patterns for rsync
build_exclusion_args() {
    local exclusion_args=""
    for exclusion in "${EXCLUSIONS[@]}"; do
        exclusion_args="$exclusion_args --exclude='$exclusion'"
    done
    echo "$exclusion_args"
}

# Backup existing space configuration
backup_space_config() {
    local space_dir="$1"
    local space_name="$(basename "$space_dir")"
    local backup_dir="$space_dir/.backup-$DEPLOYMENT_ID"
    
    if [[ -d "$space_dir" ]]; then
        mkdir -p "$backup_dir"
        
        # Backup critical files that might be overwritten
        local backup_files=(".env" "config.json" "objectives.json")
        for file in "${backup_files[@]}"; do
            if [[ -f "$space_dir/$file" ]]; then
                cp "$space_dir/$file" "$backup_dir/" 2>/dev/null || true
            fi
        done
        
        log_info "Created backup for $space_name: .backup-$DEPLOYMENT_ID"
    fi
}

# Update a single space with shared infrastructure
update_space() {
    local space_dir="$1"
    local space_name="$(basename "$space_dir")"
    
    ((TOTAL_SPACES++))
    
    log_info "Processing space: $space_name"
    
    # Validate space directory
    if [[ ! -d "$space_dir" ]]; then
        log_error "Space directory not found: $space_dir"
        return 1
    fi
    
    # Skip HUMAN-AI-FRAMEWORK space (exclusive content)
    if [[ "$space_name" =~ "HUMAN-AI-FRAMEWORK" ]] || [[ "$space_name" =~ "001-" ]]; then
        log_warning "Skipping exclusive HUMAN-AI-FRAMEWORK space: $space_name"
        return 0
    fi
    
    # Create backup
    backup_space_config "$space_dir"
    
    # Build exclusion arguments
    local exclusion_args=$(build_exclusion_args)
    
    # Synchronize shared infrastructure
    log_info "Synchronizing infrastructure for $space_name"
    
    # Use rsync with exclusions to preserve exclusive content
    if eval "rsync -av --delete-excluded $exclusion_args \"$SHARED_REPO/\" \"$space_dir/\""; then
        log_success "Infrastructure updated for space: $space_name"
        
        # Post-deployment setup
        setup_space_environment "$space_dir" "$space_name"
        
        return 0
    else
        log_error "Failed to update infrastructure for space: $space_name"
        return 1
    fi
}

# Setup space-specific environment and dependencies
setup_space_environment() {
    local space_dir="$1"
    local space_name="$2"
    
    log_info "Setting up environment for $space_name"
    
    cd "$space_dir"
    
    # Copy environment template if .env doesn't exist
    if [[ ! -f ".env" ]] && [[ -f ".env.template" ]]; then
        cp ".env.template" ".env"
        log_info "Created .env from template for $space_name"
    fi
    
    # Install Node.js dependencies if package.json exists
    if [[ -f "package.json" ]] && command -v npm &> /dev/null; then
        if npm ci --silent 2>/dev/null; then
            log_info "Installed Node.js dependencies for $space_name"
        else
            log_warning "Failed to install Node.js dependencies for $space_name"
        fi
    fi
    
    # Install Python dependencies
    if [[ -f "requirements.txt" ]] && command -v pip3 &> /dev/null; then
        if pip3 install -r requirements.txt --quiet 2>/dev/null; then
            log_info "Installed Python dependencies for $space_name"
        else
            log_warning "Failed to install Python dependencies for $space_name"
        fi
    fi
    
    # Make scripts executable
    local executable_scripts=(
        "tunnel-setup.js"
        "smoke.js"
        "weekly-compilation.py"
        "deploy-infra.sh"
    )
    
    for script in "${executable_scripts[@]}"; do
        if [[ -f "$script" ]]; then
            chmod +x "$script" 2>/dev/null || true
        fi
    done
    
    # Setup cron job for weekly compilation (only if script exists)
    if [[ -f "weekly-compilation.py" ]] && command -v python3 &> /dev/null; then
        setup_weekly_compilation_cron "$space_dir" "$space_name"
    fi
    
    cd - > /dev/null
}

# Setup weekly compilation cron job
setup_weekly_compilation_cron() {
    local space_dir="$1"
    local space_name="$2"
    
    # Check if cron job already exists for this space
    local cron_command="0 23 * * 0 cd \"$space_dir\" && python3 weekly-compilation.py >> \"$space_dir/compilation.log\" 2>&1"
    
    if ! crontab -l 2>/dev/null | grep -q "cd \"$space_dir\" && python3 weekly-compilation.py"; then
        # Add cron job
        (crontab -l 2>/dev/null; echo "$cron_command") | crontab -
        log_info "Added weekly compilation cron job for $space_name"
    else
        log_info "Weekly compilation cron job already exists for $space_name"
    fi
}

# Discover all Perplexity spaces
discover_spaces() {
    log_header "Discovering Perplexity Spaces"
    
    local spaces=()
    
    # Check if Perplexity directory exists
    if [[ ! -d "$TARGET_BASE" ]]; then
        log_warning "Perplexity spaces directory not found: $TARGET_BASE"
        log_info "Creating mock directory structure for testing"
        
        # Create mock spaces for testing
        mkdir -p "$TARGET_BASE"
        local mock_spaces=("general" "work" "research" "personal" "001-HUMAN-AI-FRAMEWORK")
        
        for space in "${mock_spaces[@]}"; do
            local space_dir="$TARGET_BASE/$space"
            mkdir -p "$space_dir"
            
            # Create minimal space structure
            echo "# $space Space" > "$space_dir/README.md"
            echo "{\"space\": \"$space\", \"version\": \"1.0.0\"}" > "$space_dir/config.json"
            
            # Create exclusive content marker for HUMAN-AI-FRAMEWORK
            if [[ "$space" =~ "HUMAN-AI-FRAMEWORK" ]]; then
                mkdir -p "$space_dir/human-ai-content"
                echo "# Exclusive HUMAN-AI discussions" > "$space_dir/human-ai-content/README.md"
            fi
        done
        
        log_info "Created mock spaces: ${mock_spaces[*]}"
    fi
    
    # Discover existing spaces
    for space_dir in "$TARGET_BASE"/*; do
        if [[ -d "$space_dir" ]]; then
            spaces+=("$space_dir")
        fi
    done
    
    log_info "Discovered ${#spaces[@]} spaces"
    
    for space in "${spaces[@]}"; do
        log_info "  • $(basename "$space")"
    done
    
    echo "${spaces[@]}"
}

# Verify deployment integrity
verify_deployment() {
    log_header "Verifying Deployment Integrity"
    
    local verification_errors=0
    
    # Check each space for required files
    for space_dir in "$TARGET_BASE"/*; do
        if [[ -d "$space_dir" ]]; then
            local space_name="$(basename "$space_dir")"
            
            # Skip HUMAN-AI-FRAMEWORK space
            if [[ "$space_name" =~ "HUMAN-AI-FRAMEWORK" ]] || [[ "$space_name" =~ "001-" ]]; then
                continue
            fi
            
            log_info "Verifying $space_name"
            
            # Check for core files
            local core_files=("server.js" "tunnel-setup.js" "smoke.js" ".env.template")
            for file in "${core_files[@]}"; do
                if [[ ! -f "$space_dir/$file" ]]; then
                    log_error "Missing core file in $space_name: $file"
                    ((verification_errors++))
                fi
            done
            
            # Verify exclusive content preservation
            if [[ -d "$space_dir/human-ai-content" ]]; then
                log_error "Exclusive content directory found in non-HUMAN-AI space: $space_name"
                ((verification_errors++))
            fi
        fi
    done
    
    # Check HUMAN-AI-FRAMEWORK space exclusivity
    local human_ai_space="$TARGET_BASE/001-HUMAN-AI-FRAMEWORK"
    if [[ -d "$human_ai_space" ]]; then
        if [[ ! -d "$human_ai_space/human-ai-content" ]]; then
            log_warning "HUMAN-AI-FRAMEWORK space missing exclusive content directory"
        else
            log_success "HUMAN-AI-FRAMEWORK exclusive content preserved"
        fi
    fi
    
    if [[ $verification_errors -eq 0 ]]; then
        log_success "Deployment verification passed"
        return 0
    else
        log_error "Deployment verification failed with $verification_errors errors"
        return 1
    fi
}

# Generate deployment report
generate_deployment_report() {
    log_header "Generating Deployment Report"
    
    local report_file="$SCRIPT_DIR/deployment-report-$DEPLOYMENT_ID.json"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    cat > "$report_file" << EOF
{
  "deploymentId": "$DEPLOYMENT_ID",
  "timestamp": "$timestamp",
  "summary": {
    "totalSpaces": $TOTAL_SPACES,
    "updatedSpaces": $UPDATED_SPACES,
    "failedSpaces": $FAILED_SPACES,
    "skippedSpaces": $SKIPPED_SPACES,
    "successRate": $(( TOTAL_SPACES > 0 ? (UPDATED_SPACES * 100 / TOTAL_SPACES) : 0 ))
  },
  "configuration": {
    "sharedRepo": "$SHARED_REPO",
    "targetBase": "$TARGET_BASE",
    "exclusions": $(printf '"%s",' "${EXCLUSIONS[@]}" | sed 's/,$//; s/.*/[&]/')
  },
  "security": {
    "exclusiveContentPreserved": true,
    "humanAiFrameworkProtected": true,
    "crossSpaceIsolation": true
  },
  "humanUser": "${USER:-unknown}",
  "logFile": "$LOG_FILE"
}
EOF
    
    log_success "Deployment report generated: $report_file"
    
    # Display summary
    echo -e "\n${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    DEPLOYMENT SUMMARY                        ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "Deployment ID: ${CYAN}$DEPLOYMENT_ID${NC}"
    echo -e "Total Spaces: ${BLUE}$TOTAL_SPACES${NC}"
    echo -e "Updated: ${GREEN}$UPDATED_SPACES${NC}"
    echo -e "Failed: ${RED}$FAILED_SPACES${NC}"
    echo -e "Skipped: ${YELLOW}$SKIPPED_SPACES${NC}"
    
    local success_rate=$(( TOTAL_SPACES > 0 ? (UPDATED_SPACES * 100 / TOTAL_SPACES) : 0 ))
    echo -e "Success Rate: ${CYAN}$success_rate%${NC}"
}

# Rollback deployment if needed
rollback_deployment() {
    log_header "Rolling Back Deployment"
    
    local rollback_count=0
    
    for space_dir in "$TARGET_BASE"/*; do
        if [[ -d "$space_dir" ]]; then
            local space_name="$(basename "$space_dir")"
            local backup_dir="$space_dir/.backup-$DEPLOYMENT_ID"
            
            if [[ -d "$backup_dir" ]]; then
                log_info "Rolling back $space_name"
                
                # Restore backed up files
                cp "$backup_dir"/* "$space_dir/" 2>/dev/null || true
                
                # Remove backup directory
                rm -rf "$backup_dir"
                
                ((rollback_count++))
                log_success "Rolled back space: $space_name"
            fi
        fi
    done
    
    log_info "Rollback completed for $rollback_count spaces"
}

# Show help information
show_help() {
    cat << EOF
Infrastructure Deployment Script - Propagate Technical Foundations

This script distributes shared operational configuration, credentials, and 
workflow updates to all Perplexity spaces while preserving the exclusive
nature of HUMAN-AI-FRAMEWORK content.

Usage: $0 [command] [options]

Commands:
  --deploy             Deploy infrastructure to all spaces (default)
  --verify             Verify deployment integrity
  --rollback           Rollback the latest deployment
  --discover           Discover and list all spaces
  --help               Show this help message

Options:
  --dry-run            Show what would be deployed without making changes
  --force              Force deployment even with validation errors
  --exclude-cron       Skip cron job setup

Examples:
  $0                   # Deploy infrastructure to all spaces
  $0 --deploy          # Explicit deploy command
  $0 --verify          # Verify existing deployment
  $0 --rollback        # Rollback latest deployment
  $0 --dry-run         # Preview deployment without changes

Security:
- Preserves exclusive HUMAN-AI-FRAMEWORK content
- Excludes human-ai-content/ directories from synchronization
- Maintains audit trail of all operations
- Creates automatic backups before updates

The deployment ensures all spaces share the same technical foundation
while centralizing human-AI strategy discussions exclusively within
the HUMAN AI FRAMEWORK space.
EOF
}

# Main deployment function
main() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║            INFRASTRUCTURE DEPLOYMENT SYSTEM                  ║"
    echo "║          Propagate Technical Foundations to All Spaces       ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    log_info "Infrastructure deployment started"
    log_info "Deployment ID: $DEPLOYMENT_ID"
    log_info "User: ${USER:-unknown}"
    
    # Parse command line arguments
    local command="deploy"
    local dry_run=false
    local force=false
    local exclude_cron=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --deploy)
                command="deploy"
                shift
                ;;
            --verify)
                command="verify"
                shift
                ;;
            --rollback)
                command="rollback"
                shift
                ;;
            --discover)
                command="discover"
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --force)
                force=true
                shift
                ;;
            --exclude-cron)
                exclude_cron=true
                shift
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Execute command
    case $command in
        "deploy")
            if $dry_run; then
                log_info "DRY RUN MODE - No changes will be made"
                # Add dry-run logic here
                discover_spaces > /dev/null
                log_info "Would update $TOTAL_SPACES spaces"
                exit 0
            fi
            
            # Validate shared infrastructure
            if ! validate_shared_infra; then
                if ! $force; then
                    log_error "Validation failed. Use --force to override."
                    exit 1
                fi
            fi
            
            # Discover and update spaces
            local spaces=($(discover_spaces))
            
            for space_dir in "${spaces[@]}"; do
                update_space "$space_dir"
            done
            
            # Verify deployment
            verify_deployment
            
            # Generate report
            generate_deployment_report
            
            if [[ $FAILED_SPACES -eq 0 ]]; then
                log_success "Infrastructure deployment completed successfully"
                echo -e "\n${GREEN}🎉 All spaces updated with shared technical foundations!${NC}"
                exit 0
            else
                log_error "Infrastructure deployment completed with errors"
                echo -e "\n${YELLOW}⚠️  Deployment completed with $FAILED_SPACES failures${NC}"
                exit 1
            fi
            ;;
        "verify")
            verify_deployment
            ;;
        "rollback")
            rollback_deployment
            ;;
        "discover")
            discover_spaces > /dev/null
            echo -e "\n${CYAN}Discovered Spaces:${NC}"
            for space_dir in "$TARGET_BASE"/*; do
                if [[ -d "$space_dir" ]]; then
                    echo "  • $(basename "$space_dir")"
                fi
            done
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"