#!/bin/bash

# Copilot Integration Quick Start Script
# This script helps you get the Copilot integration running quickly

set -e

echo "🚀 Copilot Integration Quick Start"
echo "=================================="

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "❌ Node.js version 18+ is required. Current version: $(node --version)"
    exit 1
fi

echo "✅ Node.js $(node --version) detected"

# Install dependencies if not already installed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
else
    echo "✅ Dependencies already installed"
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "📝 Creating .env file from template..."
    cp .env.example .env
    echo "⚠️  Please edit .env file with your actual values before continuing"
    echo "   Required: COPILOT_API_KEY, SLACK_SIGNING_SECRET, SLACK_BOT_TOKEN"
    echo ""
    read -p "Press Enter when you've configured .env file..."
fi

# Copy .env to copilot directory
cp .env copilot/.env

echo ""
echo "🔥 Starting services..."
echo "======================"

# Function to cleanup background processes
cleanup() {
    echo ""
    echo "🛑 Shutting down services..."
    pkill -f "node copilot/server.js" 2>/dev/null || true
    pkill -f "node webhook-multiplexer.js" 2>/dev/null || true
    echo "✅ Cleanup complete"
    exit 0
}

# Set up cleanup on script exit
trap cleanup EXIT INT TERM

# Start Copilot agent in background
echo "🤖 Starting Copilot agent..."
node copilot/server.js > copilot.log 2>&1 &
COPILOT_PID=$!

# Wait for Copilot agent to start
sleep 3

# Check if Copilot agent is healthy
if curl -f -s http://localhost:4000/health > /dev/null; then
    echo "✅ Copilot agent is running"
else
    echo "❌ Copilot agent failed to start. Check copilot.log for details."
    cat copilot.log
    exit 1
fi

# Start webhook multiplexer in background
echo "🪝 Starting webhook multiplexer..."
node webhook-multiplexer.js > webhook.log 2>&1 &
WEBHOOK_PID=$!

# Wait for webhook multiplexer to start
sleep 3

# Check if webhook multiplexer is healthy
if curl -f -s http://localhost:3000/health > /dev/null; then
    echo "✅ Webhook multiplexer is running"
else
    echo "❌ Webhook multiplexer failed to start. Check webhook.log for details."
    cat webhook.log
    exit 1
fi

echo ""
echo "🧪 Running smoke tests..."
echo "========================"

if node scripts/smoke.js; then
    echo ""
    echo "🎉 All services are running successfully!"
    echo ""
    echo "📊 Service Status:"
    echo "- Copilot agent: http://localhost:4000/health"
    echo "- Webhook multiplexer: http://localhost:3000/health"
    echo ""
    echo "🔗 Endpoints:"
    echo "- Webhook: http://localhost:3000/webhook"
    echo "- Test: http://localhost:3000/test"
    echo ""
    echo "📋 Next steps:"
    echo "1. Set up ngrok tunnel: npm run tunnel"
    echo "2. Configure Slack webhook URL"
    echo "3. Test with real Slack events"
    echo ""
    echo "Press Ctrl+C to stop all services..."
    
    # Keep script running and display logs
    tail -f copilot.log webhook.log
else
    echo "❌ Smoke tests failed. Check the logs above for details."
    exit 1
fi