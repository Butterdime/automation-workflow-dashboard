<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# Copilot Integration Project Instructions

This project implements a complete Copilot agent integration with webhook multiplexing, secure tunneling, and CI/CD automation.

## Project Structure
- `copilot/` - Local Copilot agent server
- `scripts/` - Utility scripts for tunneling and testing
- `.github/workflows/` - CI/CD automation
- `webhook-multiplexer.js` - Main webhook handling service

## Development Guidelines
- Use ES6 modules throughout the project
- All services should use environment variables for configuration
- Implement proper error handling and logging
- Follow secure webhook signature verification practices
- Ensure all endpoints are properly authenticated

## Key Components
1. Local Copilot agent server with Express.js
2. Ngrok tunnel setup for secure external access
3. Slack webhook multiplexer with signature verification
4. Automated smoke testing
5. GitHub Actions CI/CD pipeline

## Environment Variables Required
- COPILOT_API_KEY
- COPILOT_PORT
- TUNNEL_SUBDOMAIN
- TUNNEL_URL
- SLACK_SIGNING_SECRET
- SLACK_BOT_TOKEN