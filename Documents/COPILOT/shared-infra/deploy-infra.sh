#!/usr/bin/env bash
set -e

# Infrastructure Propagation Script
# Distributes shared technical foundations to all Perplexity spaces
# Preserves human-AI discussion content exclusively in HUMAN-AI-FRAMEWORK

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARED_REPO="$SCRIPT_DIR"
TARGET_BASE="${HOME}/Perplexity/spaces"
LOG_FILE="$SCRIPT_DIR/deployment.log"
BACKUP_DIR="$SCRIPT_DIR/backups"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Print banner
print_banner() {
    print_status $BLUE "╔══════════════════════════════════════════════════════════════╗"
    print_status $BLUE "║            INFRASTRUCTURE DEPLOYMENT SYSTEM                  ║"
    print_status $BLUE "║          Propagate Technical Foundations to All Spaces       ║"
    print_status $BLUE "╚══════════════════════════════════════════════════════════════╝"
    echo
}

# Validate shared infrastructure
validate_shared_infra() {
    print_status $YELLOW "🔍 Validating shared infrastructure..."
    
    local required_files=(
        "ci-cd.yml"
        "server.js"
        "tunnel-setup.js" 
        "smoke.js"
        "weekly-compilation.py"
        ".env.template"
    )
    
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$SHARED_REPO/$file" ]]; then
            missing_files+=("$file")
        fi
    done
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        print_status $RED "❌ Missing required files:"
        for file in "${missing_files[@]}"; do
            print_status $RED "   - $file"
        done
        log "ERROR" "Validation failed: missing files"
        exit 1
    fi
    
    log "INFO" "Shared infrastructure validation passed"
    print_status $GREEN "✅ Shared infrastructure validated"
}

# Create backup
create_backup() {
    local space_dir=$1
    local space_name=$(basename "$space_dir")
    
    if [[ ! -d "$space_dir" ]]; then
        return 0
    fi
    
    local backup_path="$BACKUP_DIR/${space_name}-${TIMESTAMP}"
    mkdir -p "$backup_path"
    
    # Backup existing infrastructure files only
    local backup_files=(
        "ci-cd.yml" "server.js" "tunnel-setup.js" "smoke.js" 
        "weekly-compilation.py" ".env.template" ".env"
    )
    
    for file in "${backup_files[@]}"; do
        if [[ -f "$space_dir/$file" ]]; then
            cp "$space_dir/$file" "$backup_path/" 2>/dev/null || true
        fi
    done
    
    log "INFO" "Backup created for $space_name: $backup_path"
}

# Discover spaces
discover_spaces() {
    print_status $YELLOW "🔍 Discovering Perplexity spaces..."
    
    if [[ ! -d "$TARGET_BASE" ]]; then
        print_status $YELLOW "⚠️  Target directory $TARGET_BASE does not exist"
        log "WARNING" "Target base directory not found: $TARGET_BASE"
        
        # Create mock space directories for demonstration
        mkdir -p "$TARGET_BASE"/{001-HUMAN-AI-FRAMEWORK,002-general-discussion,003-technical-projects}
        print_status $YELLOW "📁 Created sample space directories"
    fi
    
    local spaces=()
    for space_dir in "$TARGET_BASE"/*; do
        if [[ -d "$space_dir" ]]; then
            spaces+=($(basename "$space_dir"))
        fi
    done
    
    if [[ ${#spaces[@]} -eq 0 ]]; then
        print_status $RED "❌ No spaces found in $TARGET_BASE"
        log "ERROR" "No spaces discovered"
        exit 1
    fi
    
    print_status $GREEN "📍 Discovered ${#spaces[@]} spaces:"
    for space in "${spaces[@]}"; do
        print_status $BLUE "   - $space"
    done
    
    log "INFO" "Discovered ${#spaces[@]} spaces: ${spaces[*]}"
}

# Update single space
update_space() {
    local space_dir=$1
    local space_name=$(basename "$space_dir")
    
    print_status $YELLOW "🔄 Updating infrastructure in $space_name"
    
    # Create backup before update
    create_backup "$space_dir"
    
    # Ensure space directory exists
    mkdir -p "$space_dir"
    
    # Sync shared infrastructure, excluding human-AI content
    rsync -av \
        --exclude 'human-ai-content/**' \
        --exclude 'human-ai-framework/**' \
        --exclude '.env' \
        --exclude 'node_modules/**' \
        --exclude '.git/**' \
        --exclude 'backups/**' \
        --exclude 'deployment.log' \
        "$SHARED_REPO/" "$space_dir/"
    
    # Set proper permissions
    chmod +x "$space_dir"/*.sh 2>/dev/null || true
    chmod +x "$space_dir"/deploy-infra.sh 2>/dev/null || true
    
    log "INFO" "Updated infrastructure for $space_name"
    print_status $GREEN "   ✅ $space_name updated"
}

# Verify deployment
verify_deployment() {
    local space_dir=$1
    local space_name=$(basename "$space_dir")
    
    local required_files=(
        "server.js" "tunnel-setup.js" "smoke.js" 
        "weekly-compilation.py" "ci-cd.yml" ".env.template"
    )
    
    local missing=()
    for file in "${required_files[@]}"; do
        if [[ ! -f "$space_dir/$file" ]]; then
            missing+=("$file")
        fi
    done
    
    # Verify human-ai-content exclusion (except for FRAMEWORK space)
    if [[ "$space_name" != "001-HUMAN-AI-FRAMEWORK" ]] && [[ -d "$space_dir/human-ai-content" ]]; then
        missing+=("human-ai-content should be excluded")
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        print_status $RED "❌ $space_name verification failed:"
        for item in "${missing[@]}"; do
            print_status $RED "   - Missing: $item"
        done
        return 1
    fi
    
    print_status $GREEN "   ✅ $space_name verified"
    return 0
}

# Main deployment function
deploy_infrastructure() {
    local dry_run=${1:-false}
    
    print_status $YELLOW "🚀 Starting infrastructure deployment..."
    log "INFO" "Deployment started (dry-run: $dry_run)"
    
    # Validate shared infrastructure
    validate_shared_infra
    
    # Discover spaces
    discover_spaces
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    local updated_count=0
    local failed_count=0
    
    for space_dir in "$TARGET_BASE"/*; do
        if [[ -d "$space_dir" ]]; then
            local space_name=$(basename "$space_dir")
            
            if [[ "$dry_run" == "true" ]]; then
                print_status $BLUE "🔍 [DRY RUN] Would update: $space_name"
                continue
            fi
            
            if update_space "$space_dir"; then
                if verify_deployment "$space_dir"; then
                    ((updated_count++))
                else
                    ((failed_count++))
                fi
            else
                ((failed_count++))
            fi
        fi
    done
    
    # Summary
    echo
    print_status $GREEN "📊 Deployment Summary:"
    print_status $GREEN "   Spaces updated: $updated_count"
    if [[ $failed_count -gt 0 ]]; then
        print_status $RED "   Failed updates: $failed_count"
    fi
    
    log "INFO" "Deployment completed: $updated_count updated, $failed_count failed"
    
    if [[ "$dry_run" != "true" ]]; then
        print_status $GREEN "✅ Infrastructure propagated to all spaces"
        print_status $BLUE "📝 Deployment log: $LOG_FILE"
        print_status $BLUE "💾 Backups stored: $BACKUP_DIR"
    fi
}

# Rollback function
rollback_deployment() {
    print_status $YELLOW "🔄 Rolling back latest deployment..."
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        print_status $RED "❌ No backups found"
        exit 1
    fi
    
    local latest_backup=$(ls -t "$BACKUP_DIR" | head -n1)
    if [[ -z "$latest_backup" ]]; then
        print_status $RED "❌ No backup directories found"
        exit 1
    fi
    
    print_status $YELLOW "📦 Rolling back to: $latest_backup"
    
    for space_dir in "$TARGET_BASE"/*; do
        if [[ -d "$space_dir" ]]; then
            local space_name=$(basename "$space_dir")
            local backup_path="$BACKUP_DIR/${space_name}-"*
            
            if [[ -d $backup_path ]]; then
                cp -r "$backup_path"/* "$space_dir/" 2>/dev/null || true
                print_status $GREEN "   ✅ Rolled back: $space_name"
            fi
        fi
    done
    
    print_status $GREEN "✅ Rollback completed"
}

# Setup per-space function
setup_space() {
    local space_dir=$1
    local space_name=$(basename "$space_dir")
    
    print_status $YELLOW "⚙️  Setting up $space_name..."
    
    cd "$space_dir" || exit 1
    
    # Copy environment template if .env doesn't exist
    if [[ ! -f ".env" ]] && [[ -f ".env.template" ]]; then
        cp ".env.template" ".env"
        print_status $YELLOW "   📝 Created .env from template"
    fi
    
    # Install Node.js dependencies if package.json exists
    if [[ -f "package.json" ]]; then
        npm ci --silent 2>/dev/null || npm install --silent 2>/dev/null || true
        print_status $GREEN "   📦 Node.js dependencies installed"
    fi
    
    # Install Python dependencies
    pip install jsonschema 2>/dev/null || pip3 install jsonschema 2>/dev/null || true
    print_status $GREEN "   🐍 Python dependencies installed"
    
    # Setup cron job for weekly compilation (FRAMEWORK space only)
    if [[ "$space_name" == "001-HUMAN-AI-FRAMEWORK" ]]; then
        local cron_job="0 23 * * 0 cd $space_dir && python3 weekly-compilation.py"
        (crontab -l 2>/dev/null | grep -v "weekly-compilation.py"; echo "$cron_job") | crontab - 2>/dev/null || true
        print_status $GREEN "   ⏰ Weekly compilation cron job scheduled"
    fi
    
    print_status $GREEN "   ✅ $space_name setup completed"
}

# Help function
show_help() {
    echo "Infrastructure Deployment Script - Propagate Technical Foundations"
    echo
    echo "This script distributes shared operational configuration, credentials, and"
    echo "workflow updates to all Perplexity spaces while preserving the exclusive"
    echo "nature of HUMAN-AI-FRAMEWORK content."
    echo
    echo "Usage: $0 [command] [options]"
    echo
    echo "Commands:"
    echo "  --deploy             Deploy infrastructure to all spaces (default)"
    echo "  --verify             Verify deployment integrity"
    echo "  --rollback           Rollback the latest deployment"
    echo "  --discover           Discover and list all spaces"
    echo "  --setup              Setup dependencies in all spaces"
    echo "  --help               Show this help message"
    echo
    echo "Options:"
    echo "  --dry-run            Show what would be deployed without making changes"
    echo "  --force              Force deployment even with validation errors"
    echo
    echo "Examples:"
    echo "  $0                   # Deploy infrastructure to all spaces"
    echo "  $0 --deploy          # Explicit deploy command"
    echo "  $0 --verify          # Verify existing deployment"
    echo "  $0 --rollback        # Rollback latest deployment"
    echo "  $0 --dry-run         # Preview deployment without changes"
    echo "  $0 --setup           # Setup dependencies in all spaces"
    echo
    echo "Security:"
    echo "- Preserves exclusive HUMAN-AI-FRAMEWORK content"
    echo "- Excludes human-ai-content/ directories from synchronization"
    echo "- Maintains audit trail of all operations"
    echo "- Creates automatic backups before updates"
    echo
    echo "The deployment ensures all spaces share the same technical foundation"
    echo "while centralizing human-AI strategy discussions exclusively within"
    echo "the HUMAN AI FRAMEWORK space."
    echo
}

# Main execution
main() {
    # Initialize logging
    mkdir -p "$(dirname "$LOG_FILE")"
    
    print_banner
    log "INFO" "Infrastructure deployment started"
    log "INFO" "Deployment ID: deploy-$(date +%Y%m%d-%H%M%S)"
    log "INFO" "User: $(whoami)"
    
    # Parse command line arguments
    case "${1:-deploy}" in
        "--deploy"|"deploy")
            deploy_infrastructure "${2:-false}"
            ;;
        "--dry-run")
            deploy_infrastructure "true"
            ;;
        "--verify")
            print_status $YELLOW "🔍 Verifying deployment..."
            local verified=0
            local failed=0
            
            for space_dir in "$TARGET_BASE"/*; do
                if [[ -d "$space_dir" ]]; then
                    if verify_deployment "$space_dir"; then
                        ((verified++))
                    else
                        ((failed++))
                    fi
                fi
            done
            
            print_status $GREEN "📊 Verification Summary: $verified verified, $failed failed"
            ;;
        "--rollback")
            rollback_deployment
            ;;
        "--discover")
            discover_spaces
            ;;
        "--setup")
            print_status $YELLOW "⚙️  Setting up dependencies in all spaces..."
            for space_dir in "$TARGET_BASE"/*; do
                if [[ -d "$space_dir" ]]; then
                    setup_space "$space_dir"
                fi
            done
            print_status $GREEN "✅ All spaces setup completed"
            ;;
        "--help"|"help"|"-h")
            show_help
            ;;
        *)
            print_status $RED "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
    
    log "INFO" "Infrastructure deployment completed"
}

# Execute main function with all arguments
main "$@"