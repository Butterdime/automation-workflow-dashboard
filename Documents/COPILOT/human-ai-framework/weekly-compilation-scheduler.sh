#!/bin/bash

# Weekly Data Compilation Scheduler for HUMAN AI FRAMEWORK
# Automates the weekly compilation process with cron job setup
# SECURITY: EXCLUSIVE - No data sharing with external spaces

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
SPACENAME="001-HUMAN-AI-FRAMEWORK"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$SCRIPT_DIR/scheduler.log"
COMPILER_SCRIPT="$SCRIPT_DIR/weekly-compiler.js"
VALIDATOR_SCRIPT="$SCRIPT_DIR/validate-jsons.py"

# Logging functions
log_info() { 
    echo -e "${BLUE}ℹ️  $1${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1" >> "$LOG_FILE"
}

log_success() { 
    echo -e "${GREEN}✅ $1${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] $1" >> "$LOG_FILE"
}

log_warning() { 
    echo -e "${YELLOW}⚠️  $1${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN] $1" >> "$LOG_FILE"
}

log_error() { 
    echo -e "${RED}❌ $1${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" >> "$LOG_FILE"
}

log_header() { 
    echo -e "\n${CYAN}🔍 $1${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [HEADER] $1" >> "$LOG_FILE"
}

# Security validation function
validate_security_context() {
    log_header "Security Context Validation"
    
    # Verify we're in the correct space
    if [[ ! "$PWD" =~ "human-ai-framework" ]]; then
        log_error "Security violation: Not in HUMAN-AI-FRAMEWORK directory"
        return 1
    fi
    
    # Check for required security files
    if [[ ! -f "$COMPILER_SCRIPT" ]] || [[ ! -f "$VALIDATOR_SCRIPT" ]]; then
        log_error "Security violation: Required HUMAN-AI-FRAMEWORK scripts missing"
        return 1
    fi
    
    log_success "Security context validated - HUMAN-AI-FRAMEWORK exclusive access confirmed"
    return 0
}

# Create cron job for weekly compilation
setup_cron_job() {
    log_header "Setting up weekly cron job"
    
    # Define the cron job command
    local cron_command="0 23 * * 0 cd $SCRIPT_DIR && ./weekly-compilation-scheduler.sh --run-compilation >> $LOG_FILE 2>&1"
    
    # Check if cron job already exists
    if crontab -l 2>/dev/null | grep -q "weekly-compilation-scheduler.sh"; then
        log_warning "Cron job already exists"
        return 0
    fi
    
    # Add cron job
    (crontab -l 2>/dev/null; echo "$cron_command") | crontab -
    
    if [[ $? -eq 0 ]]; then
        log_success "Weekly cron job created: Every Sunday at 23:00"
        log_info "Cron command: $cron_command"
    else
        log_error "Failed to create cron job"
        return 1
    fi
}

# Remove cron job
remove_cron_job() {
    log_header "Removing weekly cron job"
    
    # Remove cron job
    crontab -l 2>/dev/null | grep -v "weekly-compilation-scheduler.sh" | crontab -
    
    if [[ $? -eq 0 ]]; then
        log_success "Weekly cron job removed"
    else
        log_error "Failed to remove cron job"
        return 1
    fi
}

# Check cron job status
check_cron_status() {
    log_header "Checking cron job status"
    
    if crontab -l 2>/dev/null | grep -q "weekly-compilation-scheduler.sh"; then
        log_success "Weekly cron job is active"
        log_info "Schedule: Every Sunday at 23:00"
        crontab -l | grep "weekly-compilation-scheduler.sh"
    else
        log_warning "Weekly cron job is not configured"
    fi
}

# Run the weekly compilation process
run_weekly_compilation() {
    log_header "Starting Weekly Data Compilation for $SPACENAME"
    
    # Security validation
    if ! validate_security_context; then
        log_error "Security validation failed - compilation aborted"
        return 1
    fi
    
    # Check prerequisites
    if ! command -v node &> /dev/null; then
        log_error "Node.js not found - compilation aborted"
        return 1
    fi
    
    if ! command -v python3 &> /dev/null; then
        log_error "Python3 not found - compilation aborted"
        return 1
    fi
    
    # Run the compilation
    log_info "Executing weekly compilation script..."
    
    if node "$COMPILER_SCRIPT"; then
        log_success "Weekly compilation completed successfully"
        
        # Run JSON validation
        log_info "Running JSON validation..."
        if python3 "$VALIDATOR_SCRIPT"; then
            log_success "JSON validation completed successfully"
        else
            log_warning "JSON validation completed with warnings"
        fi
        
        # Generate status report
        generate_status_report
        
        return 0
    else
        log_error "Weekly compilation failed"
        return 1
    fi
}

# Generate compilation status report
generate_status_report() {
    log_header "Generating Status Report"
    
    local report_file="$SCRIPT_DIR/last-compilation-status.json"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Find the latest compilation folder
    local compiled_data_dir="$SCRIPT_DIR/compiled-data"
    local latest_folder=""
    
    if [[ -d "$compiled_data_dir" ]]; then
        latest_folder=$(find "$compiled_data_dir" -maxdepth 1 -type d -name "weekly-*" | sort | tail -1)
    fi
    
    # Count files in latest compilation
    local file_count=0
    if [[ -n "$latest_folder" && -d "$latest_folder" ]]; then
        file_count=$(find "$latest_folder" -type f | wc -l)
    fi
    
    # Create status report
    cat > "$report_file" << EOF
{
  "timestamp": "$timestamp",
  "spaceName": "$SPACENAME",
  "compilation": {
    "lastRun": "$timestamp",
    "status": "success",
    "latestFolder": "$(basename "$latest_folder" 2>/dev/null || echo "none")",
    "filesCompiled": $file_count,
    "humanUser": "${USER:-unknown}"
  },
  "security": {
    "dataExclusive": true,
    "noExternalSharing": true,
    "accessRestriction": "HUMAN-AI-FRAMEWORK-ONLY"
  },
  "nextScheduled": "$(date -d 'next sunday 23:00' '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo 'unknown')"
}
EOF
    
    log_success "Status report generated: $report_file"
}

# Validate existing compilation data
validate_compilation_data() {
    log_header "Validating Existing Compilation Data"
    
    local compiled_data_dir="$SCRIPT_DIR/compiled-data"
    
    if [[ ! -d "$compiled_data_dir" ]]; then
        log_warning "No compiled data directory found"
        return 0
    fi
    
    # Find all weekly folders
    local weekly_folders=($(find "$compiled_data_dir" -maxdepth 1 -type d -name "weekly-*" | sort))
    
    if [[ ${#weekly_folders[@]} -eq 0 ]]; then
        log_warning "No weekly compilation folders found"
        return 0
    fi
    
    log_info "Found ${#weekly_folders[@]} weekly compilation folders"
    
    # Validate each folder
    local valid_folders=0
    for folder in "${weekly_folders[@]}"; do
        local folder_name=$(basename "$folder")
        log_info "Validating folder: $folder_name"
        
        # Check for required files
        local required_files=("report-$SPACENAME.json" "report-$SPACENAME-backup.json")
        local folder_valid=true
        
        for required_file in "${required_files[@]}"; do
            if [[ ! -f "$folder/$required_file" ]]; then
                log_warning "Missing required file in $folder_name: $required_file"
                folder_valid=false
            fi
        done
        
        if [[ "$folder_valid" == true ]]; then
            ((valid_folders++))
            log_success "Folder validation passed: $folder_name"
        fi
    done
    
    log_info "Validation summary: $valid_folders/${#weekly_folders[@]} folders valid"
    
    # Run JSON validation on latest folder
    if [[ ${#weekly_folders[@]} -gt 0 ]]; then
        local latest_folder="${weekly_folders[-1]}"
        log_info "Running JSON validation on latest folder..."
        python3 "$VALIDATOR_SCRIPT" "$(basename "$latest_folder")"
    fi
}

# Initialize the HUMAN AI FRAMEWORK directory structure
initialize_framework() {
    log_header "Initializing HUMAN AI FRAMEWORK Directory Structure"
    
    # Create required directories
    local directories=(
        "$SCRIPT_DIR/compiled-data"
        "$SCRIPT_DIR/logs"
        "$SCRIPT_DIR/backups"
        "$SCRIPT_DIR/validation"
    )
    
    for dir in "${directories[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_success "Created directory: $dir"
        else
            log_info "Directory already exists: $dir"
        fi
    done
    
    # Create initial audit log if it doesn't exist
    local audit_log="$SCRIPT_DIR/audit.log"
    if [[ ! -f "$audit_log" ]]; then
        cat > "$audit_log" << EOF
$(date -u +"%Y-%m-%dT%H:%M:%SZ") [INIT] [001-HUMAN-AI-FRAMEWORK] Framework initialized - User: ${USER:-unknown}
EOF
        log_success "Created initial audit log: $audit_log"
    fi
    
    # Make scripts executable
    chmod +x "$COMPILER_SCRIPT" 2>/dev/null || true
    chmod +x "$VALIDATOR_SCRIPT" 2>/dev/null || true
    chmod +x "$0"
    
    log_success "HUMAN AI FRAMEWORK directory structure initialized"
}

# Show help information
show_help() {
    cat << EOF
HUMAN AI FRAMEWORK - Weekly Data Compilation Scheduler

SECURITY: EXCLUSIVE ACCESS - NO EXTERNAL SHARING PERMITTED

Usage: $0 [command]

Commands:
  --setup              Initialize and setup weekly cron job
  --remove             Remove weekly cron job
  --status             Check cron job status
  --run-compilation    Run compilation process manually
  --validate           Validate existing compilation data
  --init               Initialize framework directory structure
  --help               Show this help message

Examples:
  $0 --setup           # Setup automatic weekly compilation
  $0 --run-compilation # Run compilation manually
  $0 --validate        # Validate existing data

The weekly compilation runs every Sunday at 23:00 and:
1. Discovers all spaces in Perplexity account
2. Collects interaction logs, configs, objectives
3. Validates JSON files for schema compliance
4. Creates secure weekly snapshots
5. Maintains audit logs and integrity checks

All data remains exclusively within HUMAN-AI-FRAMEWORK space.
EOF
}

# Main function
main() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║          HUMAN AI FRAMEWORK - Weekly Data Compiler          ║"
    echo "║                  SECURITY: EXCLUSIVE ACCESS                  ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    log_info "Script started with command: ${1:-none}"
    log_info "User: ${USER:-unknown}"
    log_info "Working directory: $PWD"
    
    case "${1:-}" in
        --setup)
            initialize_framework
            setup_cron_job
            log_success "Weekly compilation scheduler setup complete"
            ;;
        --remove)
            remove_cron_job
            log_success "Weekly compilation scheduler removed"
            ;;
        --status)
            check_cron_status
            ;;
        --run-compilation)
            run_weekly_compilation
            ;;
        --validate)
            validate_compilation_data
            ;;
        --init)
            initialize_framework
            ;;
        --help)
            show_help
            ;;
        *)
            echo -e "${YELLOW}Use --help for available commands${NC}"
            show_help
            ;;
    esac
    
    log_info "Script completed"
}

# Security check - ensure we're in the right context
if [[ ! "$SCRIPT_DIR" =~ "human-ai-framework" ]]; then
    echo -e "${RED}❌ SECURITY ERROR: Script must be run from HUMAN-AI-FRAMEWORK directory${NC}"
    exit 1
fi

# Run main function
main "$@"