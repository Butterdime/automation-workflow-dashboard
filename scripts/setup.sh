#!/bin/bash

# Setup script for Approval-Driven CI/CD Dashboard
# This script automates the initial setup process

set -e

echo "🚀 Setting up Approval-Driven CI/CD Dashboard..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node --version | cut -d'.' -f1 | sed 's/v//')
if [ "$NODE_VERSION" -lt 18 ]; then
    print_error "Node.js version 18+ is required. Current version: $(node --version)"
    exit 1
fi

print_status "Node.js version check passed: $(node --version)"

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    print_error "npm is not installed. Please install npm first."
    exit 1
fi

print_status "npm version: $(npm --version)"

# Install API dependencies
print_status "Installing API dependencies..."
cd api
if [ ! -f package.json ]; then
    print_error "package.json not found in api directory"
    exit 1
fi

npm install
print_status "API dependencies installed successfully"

# Install Dashboard dependencies
print_status "Installing Dashboard dependencies..."
cd ../dashboard
if [ ! -f package.json ]; then
    print_error "package.json not found in dashboard directory"
    exit 1
fi

npm install
print_status "Dashboard dependencies installed successfully"

# Go back to root directory
cd ..

# Create .env file if it doesn't exist
if [ ! -f api/.env ]; then
    print_status "Creating .env file from template..."
    cp api/.env.example api/.env
    print_warning "Please edit api/.env with your actual values:"
    print_warning "  - GITHUB_TOKEN: Your GitHub Personal Access Token"
    print_warning "  - DASHBOARD_ORIGIN: Your dashboard URL"
    print_warning "  - Other configuration as needed"
fi

# Commit the lockfiles if this is a git repository
if [ -d .git ]; then
    print_status "Adding lockfiles to git..."
    
    if [ -f api/package-lock.json ]; then
        git add api/package-lock.json
    fi
    
    if [ -f dashboard/package-lock.json ]; then
        git add dashboard/package-lock.json
    fi
    
    git add .gitignore
    
    if ! git diff --cached --exit-code > /dev/null; then
        git commit -m "chore: add lockfiles and gitignore configuration"
        print_status "Lockfiles committed to git"
    else
        print_status "No changes to commit"
    fi
fi

# Check if Vercel CLI is installed
if command -v vercel &> /dev/null; then
    print_status "Vercel CLI detected: $(vercel --version)"
else
    print_warning "Vercel CLI not found. Install with: npm install -g vercel"
fi

# Create launch scripts
print_status "Creating launch scripts..."

# Create start-dev.sh
cat > start-dev.sh << 'EOF'
#!/bin/bash

echo "🚀 Starting Approval CI Dashboard in development mode..."

# Start API server in background
echo "Starting API server on port 3000..."
cd api
npm run dev &
API_PID=$!

# Wait a moment for API to start
sleep 3

# Start dashboard
echo "Starting dashboard on port 3001..."
cd ../dashboard
npm run dev &
DASHBOARD_PID=$!

echo "✅ Both servers started!"
echo "📊 Dashboard: http://localhost:3001"
echo "🔧 API: http://localhost:3000"
echo "❤️  Health check: http://localhost:3000/health"

# Function to cleanup processes
cleanup() {
    echo "Stopping servers..."
    kill $API_PID $DASHBOARD_PID 2>/dev/null || true
    exit
}

# Trap cleanup on script exit
trap cleanup EXIT INT TERM

# Wait for user to stop
echo "Press Ctrl+C to stop both servers..."
wait
EOF

chmod +x start-dev.sh

# Create deployment script
cat > deploy.sh << 'EOF'
#!/bin/bash

echo "🚀 Deploying to Vercel..."

# Check if logged in to Vercel
if ! vercel whoami &> /dev/null; then
    echo "Please login to Vercel first: vercel login"
    exit 1
fi

# Deploy to production
vercel --prod

echo "✅ Deployment complete!"
echo "🔗 Check your Vercel dashboard for the live URL"
EOF

chmod +x deploy.sh

print_status "Setup completed successfully! 🎉"
echo ""
echo "Next steps:"
echo "1. Edit api/.env with your GitHub token and configuration"
echo "2. Update the organization list in dashboard/approval-dashboard.html"
echo "3. Run './start-dev.sh' to start development servers"
echo "4. Run './deploy.sh' when ready to deploy to production"
echo ""
echo "For more information, see README.md"