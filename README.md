# 🚀 Approval-Driven CI/CD Dashboard

A modern, responsive dashboard for managing approval-driven CI/CD workflows across multiple GitHub organizations. This system provides a centralized interface for approving and monitoring deployments with full audit trails and automated feedback loops.

## ✨ Features

- **Multi-Organization Support**: Monitor and manage multiple GitHub organizations from a single dashboard
- **Approval Workflow**: One-click approval system with automated rollout execution
- **Real-time Status**: Live monitoring of deployment status and workflow execution
- **Audit Trail**: Complete logging and tracking of all approval actions
- **Responsive Design**: Works seamlessly on desktop and mobile devices
- **GitHub Integration**: Deep integration with GitHub Actions and repository dispatch events
- **Automated Monitoring**: Post-deployment health checks and feedback loops

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Dashboard     │    │   API Server    │    │ GitHub Actions  │
│   (Frontend)    │◄──►│   (Backend)     │◄──►│   (Workflows)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                       │                       │
        │                       │                       │
        ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Vercel      │    │   GitHub API    │    │   Audit Logs   │
│   (Hosting)     │    │ (Integration)   │    │  (Monitoring)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📁 Project Structure

```
approval-ci-dashboard/
├── api/                          # Backend API server
│   ├── server.js                 # Main Express server
│   ├── package.json              # API dependencies
│   └── .env.example              # Environment variables template
├── dashboard/                    # Frontend dashboard
│   ├── approval-dashboard.html   # Main dashboard interface
│   └── package.json              # Frontend dependencies
├── .github/workflows/            # GitHub Actions workflows
│   └── approved-rollout.yml      # Automated deployment workflow
├── scripts/                      # Utility scripts
├── config/                       # Configuration files
├── vercel.json                   # Vercel deployment config
├── TODO.md                       # Project roadmap and tasks
└── README.md                     # This file
```

## 🚀 Quick Start

### Prerequisites

- Node.js 18+ installed
- GitHub Personal Access Token with appropriate permissions
- Vercel account (for deployment)
- Git repository access

### 1. Clone and Setup

```bash
git clone <your-repo-url>
cd approval-ci-dashboard
```

### 2. Install Dependencies

```bash
# Install API dependencies
cd api
npm install

# Install Dashboard dependencies
cd ../dashboard
npm install
```

### 3. Environment Configuration

```bash
# Copy environment template
cp api/.env.example api/.env

# Edit with your values
nano api/.env
```

Required environment variables:
- `GITHUB_TOKEN`: GitHub Personal Access Token
- `DASHBOARD_ORIGIN`: Your dashboard URL (for CORS)
- `PORT`: API server port (default: 3000)

### 4. Development

```bash
# Start API server
cd api
npm run dev

# Start dashboard (in another terminal)
cd dashboard
npm run dev
```

The dashboard will be available at `http://localhost:3001` and the API at `http://localhost:3000`.

### 5. Configure Organizations

Edit the organizations list in `dashboard/approval-dashboard.html`:

```javascript
const CONFIG = {
    API_BASE_URL: 'http://localhost:3000',
    ORGANIZATIONS: [
        'your-org-1',
        'your-org-2',
        'your-org-3'
    ]
};
```

## 🌐 Deployment

### Vercel Deployment

1. **Setup Vercel Environment Variables**:
   ```bash
   vercel env add GITHUB_TOKEN
   vercel env add DASHBOARD_ORIGIN
   ```

2. **Deploy to Production**:
   ```bash
   vercel --prod
   ```

3. **Verify Deployment**:
   - Check the dashboard loads correctly
   - Test API endpoints
   - Verify GitHub webhook integration

### GitHub Actions Setup

1. **Add Repository Secrets**:
   - `VERCEL_TOKEN`: Vercel deployment token
   - `VERCEL_ORG_ID`: Your Vercel organization ID
   - `VERCEL_PROJECT_ID`: Your Vercel project ID
   - `DASHBOARD_URL`: Your deployed dashboard URL

2. **Configure Workflow**:
   - Update organization list in `.github/workflows/approved-rollout.yml`
   - Adjust deployment environments as needed
   - Configure notification webhooks

## 🔧 Configuration

### Dashboard Configuration

The dashboard can be customized by modifying the `CONFIG` object in `approval-dashboard.html`:

```javascript
const CONFIG = {
    API_BASE_URL: 'https://your-api.vercel.app',
    ORGANIZATIONS: ['org1', 'org2', 'org3'],
    REFRESH_INTERVAL: 30000, // 30 seconds
    // Add more configuration options as needed
};
```

### API Configuration

The API server is configured through environment variables:

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `GITHUB_TOKEN` | GitHub Personal Access Token | Yes | - |
| `DASHBOARD_ORIGIN` | Dashboard URL for CORS | Yes | `http://localhost:3001` |
| `PORT` | API server port | No | `3000` |
| `NODE_ENV` | Environment mode | No | `development` |

### Workflow Configuration

The GitHub Actions workflow can be customized in `.github/workflows/approved-rollout.yml`:

- **Allowed Organizations**: Update the `ALLOWED_ORGS` list
- **Deployment Environments**: Modify the environment targets
- **Monitoring Checks**: Add custom health checks
- **Notification Settings**: Configure alerts and webhooks

## 📊 Usage

### Approving Rollouts

1. **Access Dashboard**: Navigate to your deployed dashboard URL
2. **Review Status**: Check the status of each organization
3. **Approve Rollout**: Click "Approve & Execute Rollout" for the desired organization
4. **Monitor Progress**: Watch the real-time status updates
5. **View Results**: Check the GitHub Actions workflow execution

### Monitoring Deployments

- **Live Status**: The dashboard auto-refreshes every 30 seconds
- **Workflow Logs**: View detailed logs in GitHub Actions
- **Health Checks**: Automated post-deployment validation
- **Audit Trail**: Complete history of all approval actions

### Bulk Operations

- **Refresh All**: Update status for all organizations
- **Approve All**: Approve all pending rollouts simultaneously

## 🔒 Security

### Authentication

- GitHub Personal Access Token for API access
- CORS protection for dashboard
- Rate limiting on API endpoints
- Environment variable protection

### Best Practices

1. Use environment variables for sensitive data
2. Implement proper GitHub token scoping
3. Enable branch protection rules
4. Regular security audits
5. Monitor access logs

## 🐛 Troubleshooting

### Common Issues

**Dashboard not loading organizations**:
- Check API server is running
- Verify CORS configuration
- Confirm GitHub token permissions

**Approval not triggering workflows**:
- Verify repository dispatch events are enabled
- Check GitHub token has repository access
- Confirm workflow file syntax

**Deployment failures**:
- Check Vercel environment variables
- Verify build configuration
- Review deployment logs

### Debug Mode

Enable debug logging by setting:
```bash
DEBUG=approval-dashboard:* npm run dev
```

## 📈 Monitoring and Metrics

The system provides comprehensive monitoring:

- **API Health Checks**: `/health` endpoint
- **Organization Status**: Real-time status monitoring
- **Workflow Metrics**: Success/failure rates
- **Audit Logs**: Complete action history
- **Performance Monitoring**: Response times and uptime

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

### Development Guidelines

- Follow existing code style
- Add appropriate error handling
- Update documentation
- Test across different browsers
- Ensure mobile responsiveness

## 📝 License

This project is licensed under the MIT License. See the LICENSE file for details.

## 🆘 Support

For support and questions:

1. Check the [Issues](https://github.com/your-org/approval-ci-dashboard/issues) page
2. Review the troubleshooting section
3. Create a new issue with detailed information

## 🎯 Roadmap

See `TODO.md` for the complete project roadmap and upcoming features.

---

**Last Updated**: 2025-10-19  
**Version**: 1.0.0  
**Status**: Production Ready