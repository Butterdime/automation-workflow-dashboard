#!/bin/bash

# Deployment script for Approval-Driven CI/CD Dashboard
# This script handles the complete deployment process to Vercel

set -e

echo "🚀 Deploying Approval-Driven CI/CD Dashboard to Vercel..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Vercel CLI is installed
if ! command -v vercel &> /dev/null; then
    print_error "Vercel CLI is not installed. Installing..."
    npm install -g vercel
fi

print_status "Vercel CLI version: $(vercel --version)"

# Check if logged in to Vercel
if ! vercel whoami &> /dev/null; then
    print_warning "Not logged in to Vercel. Please login..."
    vercel login
fi

print_status "Logged in as: $(vercel whoami)"

# Validate project structure
print_status "Validating project structure..."

if [ ! -f "api/server.js" ]; then
    print_error "Missing api/server.js - the Express API server"
    exit 1
fi

if [ ! -f "dashboard/approval-dashboard.html" ]; then
    print_error "Missing dashboard/approval-dashboard.html - the frontend dashboard"
    exit 1
fi

if [ ! -f "vercel.json" ]; then
    print_error "Missing vercel.json - the deployment configuration"
    exit 1
fi

print_status "Project structure validated ✓"

# Check environment variables
print_status "Checking environment variables..."

# List current environment variables (but don't show values for security)
VERCEL_ENVS=$(vercel env ls 2>/dev/null || echo "")

if echo "$VERCEL_ENVS" | grep -q "GITHUB_TOKEN"; then
    print_status "GITHUB_TOKEN environment variable is configured ✓"
else
    print_warning "GITHUB_TOKEN not found in Vercel environment variables"
    echo "To add it, run: vercel env add GITHUB_TOKEN"
fi

if echo "$VERCEL_ENVS" | grep -q "DASHBOARD_ORIGIN"; then
    print_status "DASHBOARD_ORIGIN environment variable is configured ✓"
else
    print_warning "DASHBOARD_ORIGIN not found. It will be auto-configured by Vercel"
fi

# Deploy to production
print_status "Deploying to production..."

# Use --prod --confirm to deploy directly to production without prompts
if vercel --prod --confirm; then
    print_status "✅ Deployment successful!"
    
    # Get deployment URL
    DEPLOYMENT_URL=$(vercel ls --limit=1 | grep "https://" | awk '{print $2}' | head -1)
    
    if [ -n "$DEPLOYMENT_URL" ]; then
        echo ""
        echo "🎉 Your Approval-Driven CI/CD Dashboard is live!"
        echo "🔗 Dashboard URL: $DEPLOYMENT_URL"
        echo "🔧 API Health Check: $DEPLOYMENT_URL/health"
        echo ""
        echo "Next steps:"
        echo "1. Update the API_BASE_URL in your dashboard configuration if needed"
        echo "2. Configure your GitHub organizations in the dashboard"
        echo "3. Test the approval workflow end-to-end"
        echo ""
    fi
else
    print_error "❌ Deployment failed!"
    echo ""
    echo "Common troubleshooting steps:"
    echo "1. Check that all required files are present (api/server.js, dashboard/approval-dashboard.html)"
    echo "2. Verify vercel.json configuration is correct"
    echo "3. Ensure you're logged in to Vercel (vercel whoami)"
    echo "4. Check Vercel logs for detailed error information"
    exit 1
fi

echo ""
print_status "Deployment process completed!"