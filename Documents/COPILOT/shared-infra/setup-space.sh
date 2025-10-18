#!/usr/bin/env bash
set -e

# Per-Space Setup Script
# Run this in each space after infrastructure deployment
# Sets up dependencies, environment, and space-specific configuration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPACE_NAME="$(basename "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_banner() {
    print_status $BLUE "╔══════════════════════════════════════════════════════════════╗"
    print_status $BLUE "║                   SPACE SETUP SYSTEM                         ║"
    print_status $BLUE "║              Configure Individual Space                       ║"
    print_status $BLUE "╚══════════════════════════════════════════════════════════════╝"
    echo
    print_status $YELLOW "🏷️  Space: $SPACE_NAME"
    print_status $YELLOW "📍 Location: $SCRIPT_DIR"
    echo
}

# Setup environment configuration
setup_environment() {
    print_status $YELLOW "⚙️  Setting up environment configuration..."
    
    # Copy environment template if .env doesn't exist
    if [[ ! -f ".env" ]] && [[ -f ".env.template" ]]; then
        cp ".env.template" ".env"
        
        # Set space-specific values in .env
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s/SPACE_NAME=.*/SPACE_NAME=$SPACE_NAME/" ".env"
        else
            # Linux
            sed -i "s/SPACE_NAME=.*/SPACE_NAME=$SPACE_NAME/" ".env"
        fi
        
        print_status $GREEN "   ✅ Created .env from template"
        print_status $YELLOW "   📝 Please edit .env to add your API keys and secrets"
    else
        print_status $BLUE "   ℹ️  .env already exists"
    fi
}

# Setup Node.js dependencies
setup_node_dependencies() {
    print_status $YELLOW "📦 Setting up Node.js dependencies..."
    
    # Create package.json if it doesn't exist
    if [[ ! -f "package.json" ]]; then
        npm init -y >/dev/null 2>&1
        print_status $GREEN "   ✅ Created package.json"
    fi
    
    # Install required dependencies
    local required_deps=("express" "node-fetch" "ngrok")
    local missing_deps=()
    
    for dep in "${required_deps[@]}"; do
        if ! npm list "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_status $YELLOW "   📥 Installing missing dependencies: ${missing_deps[*]}"
        npm install "${missing_deps[@]}" --silent
        print_status $GREEN "   ✅ Node.js dependencies installed"
    else
        print_status $BLUE "   ℹ️  All Node.js dependencies already installed"
    fi
}

# Setup Python dependencies
setup_python_dependencies() {
    print_status $YELLOW "🐍 Setting up Python dependencies..."
    
    # Check if pip is available
    local pip_cmd="pip3"
    if ! command -v pip3 >/dev/null 2>&1; then
        pip_cmd="pip"
        if ! command -v pip >/dev/null 2>&1; then
            print_status $RED "   ❌ pip not found - please install Python and pip"
            return 1
        fi
    fi
    
    # Install required Python packages
    local python_deps=("jsonschema" "requests")
    
    for dep in "${python_deps[@]}"; do
        if ! $pip_cmd show "$dep" >/dev/null 2>&1; then
            print_status $YELLOW "   📥 Installing $dep..."
            $pip_cmd install "$dep" --quiet --user 2>/dev/null || $pip_cmd install "$dep" --quiet
        fi
    done
    
    print_status $GREEN "   ✅ Python dependencies installed"
}

# Setup cron job for weekly compilation (FRAMEWORK space only)
setup_cron_job() {
    if [[ "$SPACE_NAME" == "001-HUMAN-AI-FRAMEWORK" ]]; then
        print_status $YELLOW "⏰ Setting up weekly compilation cron job..."
        
        local cron_job="0 23 * * 0 cd $SCRIPT_DIR && python3 weekly-compilation.py >> logs/cron.log 2>&1"
        
        # Check if cron job already exists
        if crontab -l 2>/dev/null | grep -q "weekly-compilation.py"; then
            print_status $BLUE "   ℹ️  Weekly compilation cron job already exists"
        else
            # Add cron job
            (crontab -l 2>/dev/null; echo "$cron_job") | crontab - 2>/dev/null || true
            print_status $GREEN "   ✅ Weekly compilation cron job scheduled (Sundays 11 PM)"
        fi
    else
        print_status $BLUE "   ℹ️  Skipping cron job setup (not HUMAN-AI-FRAMEWORK space)"
    fi
}

# Setup GitHub workflow
setup_github_workflow() {
    print_status $YELLOW "🔄 Setting up GitHub CI/CD workflow..."
    
    # Create .github/workflows directory
    mkdir -p ".github/workflows"
    
    # Copy example workflow if it doesn't exist
    if [[ ! -f ".github/workflows/ci-cd.yml" ]] && [[ -f "example-space-ci-cd.yml" ]]; then
        cp "example-space-ci-cd.yml" ".github/workflows/ci-cd.yml"
        
        # Update space name in workflow
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s/space_name: .*/space_name: $SPACE_NAME/" ".github/workflows/ci-cd.yml"
            
            # Set skip_framework_tasks appropriately
            if [[ "$SPACE_NAME" == "001-HUMAN-AI-FRAMEWORK" ]]; then
                sed -i '' "s/skip_framework_tasks: true/skip_framework_tasks: false/" ".github/workflows/ci-cd.yml"
            fi
        else
            # Linux
            sed -i "s/space_name: .*/space_name: $SPACE_NAME/" ".github/workflows/ci-cd.yml"
            
            if [[ "$SPACE_NAME" == "001-HUMAN-AI-FRAMEWORK" ]]; then
                sed -i "s/skip_framework_tasks: true/skip_framework_tasks: false/" ".github/workflows/ci-cd.yml"
            fi
        fi
        
        print_status $GREEN "   ✅ GitHub workflow configured"
    else
        print_status $BLUE "   ℹ️  GitHub workflow already exists"
    fi
}

# Setup logs directory
setup_logs_directory() {
    print_status $YELLOW "📁 Setting up logs directory..."
    
    mkdir -p "logs"
    
    # Create .gitkeep file to ensure logs directory is tracked
    if [[ ! -f "logs/.gitkeep" ]]; then
        touch "logs/.gitkeep"
    fi
    
    # Setup log rotation (create logrotate config)
    cat > "logs/logrotate.conf" << 'EOF'
logs/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644
}
EOF
    
    print_status $GREEN "   ✅ Logs directory configured"
}

# Validate setup
validate_setup() {
    print_status $YELLOW "🔍 Validating setup..."
    
    local validation_errors=()
    
    # Check required files
    local required_files=(
        "server.js" "tunnel-setup.js" "smoke.js" 
        "weekly-compilation.py" ".env.template"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            validation_errors+=("Missing file: $file")
        fi
    done
    
    # Check .env exists
    if [[ ! -f ".env" ]]; then
        validation_errors+=("Missing .env file")
    fi
    
    # Check Node.js dependencies
    if [[ -f "package.json" ]]; then
        for dep in express node-fetch ngrok; do
            if ! npm list "$dep" >/dev/null 2>&1; then
                validation_errors+=("Missing Node.js dependency: $dep")
            fi
        done
    fi
    
    # Check directories
    for dir in logs .github/workflows; do
        if [[ ! -d "$dir" ]]; then
            validation_errors+=("Missing directory: $dir")
        fi
    done
    
    if [[ ${#validation_errors[@]} -gt 0 ]]; then
        print_status $RED "   ❌ Validation failed:"
        for error in "${validation_errors[@]}"; do
            print_status $RED "      - $error"
        done
        return 1
    fi
    
    print_status $GREEN "   ✅ Setup validation passed"
    return 0
}

# Run quick smoke test
run_quick_test() {
    print_status $YELLOW "🧪 Running quick setup verification..."
    
    # Test server syntax
    if node -c server.js 2>/dev/null; then
        print_status $GREEN "   ✅ Server.js syntax valid"
    else
        print_status $RED "   ❌ Server.js syntax error"
    fi
    
    # Test Python syntax
    if python3 -m py_compile weekly-compilation.py 2>/dev/null; then
        print_status $GREEN "   ✅ Weekly-compilation.py syntax valid"
    else
        print_status $RED "   ❌ Weekly-compilation.py syntax error"
    fi
    
    # Test environment file
    if [[ -f ".env" ]]; then
        if grep -q "SPACE_NAME=$SPACE_NAME" ".env"; then
            print_status $GREEN "   ✅ Environment configured correctly"
        else
            print_status $YELLOW "   ⚠️  SPACE_NAME may not be set correctly in .env"
        fi
    fi
}

# Main setup function
main() {
    print_banner
    
    print_status $YELLOW "🚀 Starting space setup for: $SPACE_NAME"
    echo
    
    # Run setup steps
    setup_environment
    setup_node_dependencies
    setup_python_dependencies
    setup_cron_job
    setup_github_workflow
    setup_logs_directory
    
    echo
    
    # Validate and test
    if validate_setup; then
        run_quick_test
        
        echo
        print_status $GREEN "🎉 Space setup completed successfully!"
        echo
        print_status $BLUE "📋 Next steps:"
        print_status $BLUE "   1. Edit .env file with your API keys and secrets"
        print_status $BLUE "   2. Test the setup: node smoke.js"
        print_status $BLUE "   3. Start the Copilot agent: node server.js"
        print_status $BLUE "   4. Setup tunnel: node tunnel-setup.js"
        
        if [[ "$SPACE_NAME" == "001-HUMAN-AI-FRAMEWORK" ]]; then
            print_status $BLUE "   5. Weekly compilation scheduled automatically (Sundays 11 PM)"
        fi
        
    else
        print_status $RED "❌ Setup validation failed - please check errors above"
        exit 1
    fi
}

# Show help
show_help() {
    echo "Per-Space Setup Script"
    echo
    echo "This script configures a Perplexity space with all necessary"
    echo "dependencies and configuration after infrastructure deployment."
    echo
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  --help               Show this help message"
    echo "  --validate-only      Only validate setup without making changes"
    echo "  --skip-deps          Skip dependency installation"
    echo "  --force              Force setup even if files exist"
    echo
    echo "Examples:"
    echo "  $0                   # Complete space setup"
    echo "  $0 --validate-only   # Validate existing setup"
    echo "  $0 --skip-deps       # Setup without installing dependencies"
    echo
}

# Parse command line arguments
case "${1:-setup}" in
    "--help"|"help"|"-h")
        show_help
        ;;
    "--validate-only")
        print_banner
        validate_setup
        ;;
    "--skip-deps")
        print_banner
        setup_environment
        setup_github_workflow
        setup_logs_directory
        validate_setup
        ;;
    "--force")
        export FORCE_SETUP=true
        main
        ;;
    *)
        main
        ;;
esac