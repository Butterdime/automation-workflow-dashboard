#!/bin/bash

# Validation script for Approval-Driven CI/CD Dashboard
# This script validates the setup and configuration

set -e

echo "🔍 Validating Approval-Driven CI/CD Dashboard setup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Function to print colored output
print_pass() {
    echo -e "  ${GREEN}✓${NC} $1"
    ((PASSED++))
}

print_fail() {
    echo -e "  ${RED}✗${NC} $1"
    ((FAILED++))
}

print_warning() {
    echo -e "  ${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

print_section() {
    echo -e "\n${BLUE}$1${NC}"
}

# Validate Node.js setup
print_section "Node.js Environment"
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    print_pass "Node.js installed: $NODE_VERSION"
    
    # Check version
    NODE_MAJOR=$(echo $NODE_VERSION | cut -d'.' -f1 | sed 's/v//')
    if [ "$NODE_MAJOR" -ge 18 ]; then
        print_pass "Node.js version is compatible (18+)"
    else
        print_fail "Node.js version is too old. Requires 18+, found $NODE_VERSION"
    fi
else
    print_fail "Node.js is not installed"
fi

if command -v npm &> /dev/null; then
    print_pass "npm installed: $(npm --version)"
else
    print_fail "npm is not installed"
fi

# Validate project structure
print_section "Project Structure"
REQUIRED_DIRS=("api" "dashboard" "scripts" ".github/workflows" "config")
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        print_pass "Directory exists: $dir"
    else
        print_fail "Missing directory: $dir"
    fi
done

REQUIRED_FILES=(
    "api/package.json"
    "api/server.js"
    "dashboard/package.json"
    "dashboard/approval-dashboard.html"
    ".github/workflows/approved-rollout.yml"
    "vercel.json"
    "README.md"
    "TODO.md"
    ".gitignore"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_pass "File exists: $file"
    else
        print_fail "Missing file: $file"
    fi
done

# Validate package.json files
print_section "Package Configuration"
if [ -f "api/package.json" ]; then
    if jq -e '.dependencies.express' api/package.json > /dev/null 2>&1; then
        print_pass "API has Express dependency"
    else
        print_fail "API missing Express dependency"
    fi
    
    if jq -e '.dependencies."@octokit/rest"' api/package.json > /dev/null 2>&1; then
        print_pass "API has GitHub Octokit dependency"
    else
        print_fail "API missing GitHub Octokit dependency"
    fi
fi

# Validate dependencies installation
print_section "Dependencies"
if [ -f "api/package-lock.json" ] || [ -f "api/yarn.lock" ]; then
    print_pass "API lockfile exists"
else
    print_warning "API lockfile missing - run 'npm install' in api directory"
fi

if [ -d "api/node_modules" ]; then
    print_pass "API dependencies installed"
else
    print_warning "API node_modules missing - run 'npm install' in api directory"
fi

if [ -f "dashboard/package-lock.json" ] || [ -f "dashboard/yarn.lock" ]; then
    print_pass "Dashboard lockfile exists"
else
    print_warning "Dashboard lockfile missing - run 'npm install' in dashboard directory"
fi

if [ -d "dashboard/node_modules" ]; then
    print_pass "Dashboard dependencies installed"
else
    print_warning "Dashboard node_modules missing - run 'npm install' in dashboard directory"
fi

# Validate configuration
print_section "Configuration"
if [ -f "api/.env" ]; then
    print_pass ".env file exists"
    
    if grep -q "GITHUB_TOKEN=" api/.env; then
        if grep -q "GITHUB_TOKEN=your_github" api/.env; then
            print_warning "GITHUB_TOKEN is still set to placeholder value"
        else
            print_pass "GITHUB_TOKEN is configured"
        fi
    else
        print_fail "GITHUB_TOKEN not found in .env"
    fi
    
    if grep -q "DASHBOARD_ORIGIN=" api/.env; then
        print_pass "DASHBOARD_ORIGIN is configured"
    else
        print_warning "DASHBOARD_ORIGIN not configured"
    fi
else
    print_warning ".env file missing - copy from .env.example and configure"
fi

# Validate GitHub workflow
print_section "GitHub Actions"
if [ -f ".github/workflows/approved-rollout.yml" ]; then
    print_pass "Approved rollout workflow exists"
    
    # Check for key workflow components
    if grep -q "repository_dispatch" .github/workflows/approved-rollout.yml; then
        print_pass "Workflow has repository_dispatch trigger"
    else
        print_fail "Workflow missing repository_dispatch trigger"
    fi
    
    if grep -q "vercel" .github/workflows/approved-rollout.yml; then
        print_pass "Workflow includes Vercel deployment"
    else
        print_warning "Workflow may be missing Vercel deployment step"
    fi
fi

# Validate Vercel configuration
print_section "Vercel Configuration"
if [ -f "vercel.json" ]; then
    print_pass "vercel.json exists"
    
    if command -v jq &> /dev/null; then
        if jq -e '.routes' vercel.json > /dev/null 2>&1; then
            print_pass "Vercel routes configured"
        else
            print_warning "Vercel routes may not be configured"
        fi
    else
        print_warning "jq not installed - cannot validate JSON structure"
    fi
else
    print_fail "vercel.json missing"
fi

# Check for Vercel CLI
if command -v vercel &> /dev/null; then
    print_pass "Vercel CLI installed: $(vercel --version)"
else
    print_warning "Vercel CLI not installed - install with 'npm install -g vercel'"
fi

# Validate dashboard configuration
print_section "Dashboard Configuration"
if [ -f "dashboard/approval-dashboard.html" ]; then
    if grep -q "your-org-1" dashboard/approval-dashboard.html; then
        print_warning "Dashboard still has placeholder organization names"
    else
        print_pass "Dashboard organizations appear to be configured"
    fi
    
    if grep -q "localhost:3000" dashboard/approval-dashboard.html; then
        print_warning "Dashboard still uses localhost API URL"
    else
        print_pass "Dashboard API URL appears to be configured"
    fi
fi

# Check git status
print_section "Git Repository"
if [ -d ".git" ]; then
    print_pass "Git repository initialized"
    
    if git remote -v | grep -q "origin"; then
        print_pass "Git remote origin configured"
    else
        print_warning "Git remote origin not configured"
    fi
    
    # Check for uncommitted changes
    if git diff --quiet && git diff --cached --quiet; then
        print_pass "Working directory is clean"
    else
        print_warning "Uncommitted changes detected"
    fi
else
    print_fail "Not a git repository"
fi

# Summary
print_section "Validation Summary"
echo "Results:"
echo "  ✓ Passed: $PASSED"
echo "  ⚠ Warnings: $WARNINGS"
echo "  ✗ Failed: $FAILED"

if [ $FAILED -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "\n${GREEN}🎉 All validations passed! Your setup is ready.${NC}"
        exit 0
    else
        echo -e "\n${YELLOW}⚠️  Setup is mostly ready, but please address the warnings above.${NC}"
        exit 0
    fi
else
    echo -e "\n${RED}❌ Setup has issues that need to be fixed before proceeding.${NC}"
    exit 1
fi