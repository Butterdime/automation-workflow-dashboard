const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const morgan = require('morgan');
const compression = require('compression');
const { Octokit } = require('@octokit/rest');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(compression());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use(limiter);

// CORS configuration
const corsOptions = {
  origin: process.env.DASHBOARD_ORIGIN || 'http://localhost:3001',
  credentials: true,
  optionsSuccessStatus: 200
};
app.use(cors(corsOptions));

// Logging
app.use(morgan('combined'));

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Initialize GitHub API client
const octokit = new Octokit({
  auth: process.env.GITHUB_TOKEN,
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Get organization status
app.get('/api/organizations/:org/status', async (req, res) => {
  try {
    const { org } = req.params;
    
    // Get latest workflow runs for the organization
    const { data: repos } = await octokit.rest.repos.listForOrg({
      org,
      sort: 'updated',
      per_page: 10
    });

    const orgStatus = {
      organization: org,
      lastUpdate: new Date().toISOString(),
      repositories: repos.length,
      status: 'active' // This would be calculated based on actual workflow status
    };

    res.json(orgStatus);
  } catch (error) {
    console.error(`Error fetching status for org ${req.params.org}:`, error.message);
    res.status(500).json({ 
      error: 'Failed to fetch organization status',
      organization: req.params.org
    });
  }
});

// Approve and execute rollout
app.post('/api/organizations/:org/approve', async (req, res) => {
  try {
    const { org } = req.params;
    const { repository = 'main-repo' } = req.body;

    // Trigger repository dispatch event
    await octokit.rest.repos.createDispatchEvent({
      owner: org,
      repo: repository,
      event_type: 'approved-rollout',
      client_payload: {
        approved_by: req.headers['x-user-id'] || 'dashboard-user',
        timestamp: new Date().toISOString(),
        organization: org
      }
    });

    res.json({
      success: true,
      message: `Rollout approved and triggered for ${org}`,
      organization: org,
      repository,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error(`Error approving rollout for org ${req.params.org}:`, error.message);
    res.status(500).json({ 
      error: 'Failed to approve rollout',
      organization: req.params.org
    });
  }
});

// Get workflow status
app.get('/api/organizations/:org/workflows', async (req, res) => {
  try {
    const { org } = req.params;
    const { repository = 'main-repo' } = req.query;

    const { data: workflows } = await octokit.rest.actions.listWorkflowRuns({
      owner: org,
      repo: repository,
      per_page: 5
    });

    res.json({
      organization: org,
      repository,
      workflows: workflows.workflow_runs.map(run => ({
        id: run.id,
        status: run.status,
        conclusion: run.conclusion,
        created_at: run.created_at,
        updated_at: run.updated_at,
        workflow_name: run.name
      }))
    });
  } catch (error) {
    console.error(`Error fetching workflows for org ${req.params.org}:`, error.message);
    res.status(500).json({ 
      error: 'Failed to fetch workflow status',
      organization: req.params.org
    });
  }
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);
  res.status(500).json({ 
    error: 'Internal server error',
    timestamp: new Date().toISOString()
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Approval CI Dashboard API running on port ${PORT}`);
  console.log(`📊 Dashboard origin: ${process.env.DASHBOARD_ORIGIN || 'http://localhost:3001'}`);
  console.log(`🔑 GitHub token configured: ${process.env.GITHUB_TOKEN ? 'Yes' : 'No'}`);
});

module.exports = app;