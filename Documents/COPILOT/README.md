# Copilot Integration Project

> Complete Copilot agent integration with webhook multiplexing, secure tunneling, and CI/CD automation.

## 🚀 Quick Start

1. **Clone and setup:**
   ```bash
   git clone <your-repo-url>
   cd copilot-integration
   npm install
   ```

2. **Configure environment:**
   ```bash
   cp .env.example .env
   # Edit .env with your actual values
   ```

3. **Start services:**
   ```bash
   # Terminal 1: Start Copilot agent
   npm run copilot

   # Terminal 2: Start tunnel (optional for local dev)
   npm run tunnel

   # Terminal 3: Start webhook multiplexer
   npm run start
   ```

4. **Test the integration:**
   ```bash
   npm run test
   ```

## 📁 Project Structure

```
copilot-integration/
├── copilot/
│   ├── server.js          # Local Copilot agent server
│   └── .env               # Copilot-specific environment variables
├── scripts/
│   ├── tunnel-setup.js    # Ngrok tunnel management
│   └── smoke.js           # Integration testing
├── .github/
│   ├── workflows/
│   │   └── deploy-hive-slack.yml  # CI/CD pipeline
│   └── copilot-instructions.md    # Project guidelines
├── webhook-multiplexer.js  # Main webhook handling service
├── package.json
├── .env.example            # Environment template
└── README.md              # This file
```

## 🔧 Components

### 1. Local Copilot Agent (`copilot/server.js`)
- Express.js server running on port 4000
- Processes requests using @hiveai/copilot-sdk
- Health check endpoint: `/health`
- Processing endpoint: `/process`

### 2. Webhook Multiplexer (`webhook-multiplexer.js`)
- Handles Slack webhook events
- Verifies Slack signatures for security
- Routes requests to Copilot agent
- Supports URL verification challenges

### 3. Secure Tunneling (`scripts/tunnel-setup.js`)
- Creates ngrok tunnel for external access
- Automatically updates environment variables
- Supports custom subdomains

### 4. Testing (`scripts/smoke.js`)
- Comprehensive integration tests
- Tests all endpoints and services
- Generates detailed test reports

## ⚙️ Configuration

### Environment Variables

Create `.env` file from `.env.example`:

```bash
# Copilot Agent Configuration
COPILOT_API_KEY=your_local_agent_key_here
COPILOT_PORT=4000

# Tunnel Configuration  
TUNNEL_SUBDOMAIN=your-tunnel-subdomain
TUNNEL_URL=https://your-tunnel-subdomain.ngrok.io

# Slack Integration
SLACK_SIGNING_SECRET=your_slack_signing_secret_here
SLACK_BOT_TOKEN=xoxb-your-slack-bot-token-here

# Optional Development Settings
NODE_ENV=development
LOG_LEVEL=info
```

### Required Secrets for GitHub Actions

Configure these secrets in your GitHub repository:

- `COPILOT_API_KEY` - Your Copilot API key
- `TUNNEL_SUBDOMAIN` - Ngrok subdomain
- `SLACK_SIGNING_SECRET` - Slack app signing secret
- `SLACK_BOT_TOKEN` - Slack bot token

## 🚀 Deployment

### Local Development

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Configure environment:**
   ```bash
   cp .env.example .env
   # Edit .env with your values
   cp .env copilot/.env
   ```

3. **Start services in order:**
   ```bash
   # Terminal 1: Copilot agent
   npm run copilot

   # Terminal 2: Setup tunnel
   npm run tunnel

   # Terminal 3: Webhook multiplexer
   npm run start
   ```

4. **Test everything:**
   ```bash
   npm run test
   ```

### Production Deployment

1. **Set up production environment variables**
2. **Deploy to your hosting platform**
3. **Configure Slack webhook URL**
4. **Run production smoke tests**

## 🧪 Testing

### Smoke Tests
```bash
npm run test
```

Tests include:
- ✅ Copilot agent health and processing
- ✅ Webhook multiplexer endpoints
- ✅ Slack signature verification
- ✅ URL verification challenges
- ✅ End-to-end integration

### Manual Testing

Test the webhook endpoint directly:
```bash
curl -X POST http://localhost:3000/test \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello Copilot!", "user": "test-user"}'
```

Test Copilot agent directly:
```bash
curl -X POST http://localhost:4000/process \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Hello!", "context": {"test": true}}'
```

## 📋 Development Scripts

- `npm start` - Start webhook multiplexer
- `npm run copilot` - Start Copilot agent
- `npm run tunnel` - Setup ngrok tunnel
- `npm run test` - Run smoke tests
- `npm run lint` - Lint code (when ESLint is configured)
- `npm run deploy` - Build and test for deployment

## 🔒 Security

- ✅ Slack signature verification
- ✅ Environment variable protection
- ✅ Request timestamp validation
- ✅ Error handling and logging
- ✅ Security audit in CI/CD

## 📊 Monitoring

### Health Checks
- Copilot agent: `http://localhost:4000/health`
- Webhook multiplexer: `http://localhost:3000/health`

### Logs
- Services log to console
- CI/CD uploads logs on failure
- Structured error messages

## 🛠️ Troubleshooting

### Common Issues

**"Copilot service unavailable"**
- Check if Copilot agent is running on correct port
- Verify COPILOT_API_KEY is set
- Check Copilot agent logs

**"Invalid signature"**
- Verify SLACK_SIGNING_SECRET matches Slack app
- Check request timestamp (must be within 5 minutes)
- Ensure raw body is used for signature verification

**"Tunnel connection failed"**
- Install ngrok: `npm install -g ngrok`
- Check TUNNEL_SUBDOMAIN availability
- Verify ngrok authentication

**"Dependencies missing"**
- Run `npm install`
- Check Node.js version (requires 18+)
- Clear node_modules and reinstall if needed

### Debug Mode

Enable detailed logging:
```bash
export LOG_LEVEL=debug
npm run start
```

### Service Status

Check all services:
```bash
# Check Copilot agent
curl http://localhost:4000/health

# Check webhook multiplexer  
curl http://localhost:3000/health

# Run comprehensive tests
npm run test
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `npm run test`
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details.

## 🆘 Support

- Check the [troubleshooting section](#troubleshooting)
- Review service logs for error details
- Run smoke tests to identify issues
- Check GitHub Actions for CI/CD status

---

**🎉 You now have a complete Copilot integration with webhook multiplexing, secure tunneling, and automated testing!**