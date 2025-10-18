import express from 'express';
import crypto from 'crypto';
import axios from 'axios';
import dotenv from 'dotenv';

dotenv.config();
const app = express();

// Middleware for parsing JSON and raw body
app.use('/webhook', express.raw({ type: 'application/json' }));
app.use(express.json());

/**
 * Verify Slack webhook signature
 * @param {Object} req - Express request object
 * @returns {boolean} - True if signature is valid
 */
function verifySlackSignature(req) {
  try {
    const timestamp = req.headers['x-slack-request-timestamp'];
    const slackSignature = req.headers['x-slack-signature'];
    
    if (!timestamp || !slackSignature) {
      console.log('Missing timestamp or signature headers');
      return false;
    }
    
    // Check if timestamp is within 5 minutes
    const currentTime = Math.floor(Date.now() / 1000);
    if (Math.abs(currentTime - timestamp) > 300) {
      console.log('Request timestamp too old');
      return false;
    }
    
    // Get raw body
    const body = req.body.toString();
    
    // Create signature base string
    const sigBaseString = `v0:${timestamp}:${body}`;
    
    // Generate expected signature
    const expectedSignature = 'v0=' + crypto
      .createHmac('sha256', process.env.SLACK_SIGNING_SECRET)
      .update(sigBaseString)
      .digest('hex');
    
    // Compare signatures
    return crypto.timingSafeEqual(
      Buffer.from(expectedSignature),
      Buffer.from(slackSignature)
    );
  } catch (error) {
    console.error('Signature verification error:', error);
    return false;
  }
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    service: 'webhook-multiplexer',
    timestamp: new Date().toISOString()
  });
});

// Main webhook endpoint
app.post('/webhook', async (req, res) => {
  try {
    console.log('📨 Received webhook request');
    
    // Verify Slack signature
    if (!verifySlackSignature(req)) {
      console.log('❌ Invalid signature');
      return res.status(400).json({ error: 'invalid_signature' });
    }
    
    // Parse the request body
    const payload = JSON.parse(req.body.toString());
    console.log('📋 Webhook payload:', payload);
    
    // Handle Slack URL verification challenge
    if (payload.type === 'url_verification') {
      console.log('🔗 URL verification challenge received');
      return res.json({ challenge: payload.challenge });
    }
    
    // Extract text from different Slack event types
    let promptText = '';
    if (payload.event) {
      // Event API format
      promptText = payload.event.text || '';
    } else if (payload.text) {
      // Slash command format
      promptText = payload.text;
    } else if (payload.message) {
      // Interactive component format
      promptText = payload.message.text || '';
    }
    
    if (!promptText) {
      console.log('⚠️  No text found in payload');
      return res.json({ text: 'No text to process' });
    }
    
    console.log(`🤖 Processing prompt: "${promptText}"`);
    
    // Call Copilot agent
    const copilotResponse = await axios.post(
      `${process.env.TUNNEL_URL}/process`,
      { 
        prompt: promptText, 
        context: {
          user: payload.user_id || payload.event?.user,
          channel: payload.channel_id || payload.event?.channel,
          timestamp: payload.event?.ts,
          team: payload.team_id
        }
      },
      {
        timeout: 30000, // 30 second timeout
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );
    
    console.log('✅ Copilot response received:', copilotResponse.data);
    
    // Return response to Slack
    res.json({ 
      text: copilotResponse.data.reply,
      response_type: 'in_channel' // or 'ephemeral' for private responses
    });
    
  } catch (error) {
    console.error('❌ Webhook processing error:', error.message);
    
    if (error.code === 'ECONNREFUSED') {
      return res.status(503).json({ 
        text: 'Copilot service is currently unavailable. Please try again later.',
        error: 'service_unavailable'
      });
    }
    
    if (error.response) {
      console.error('Copilot API error:', error.response.data);
      return res.status(500).json({ 
        text: 'Sorry, I encountered an error processing your request.',
        error: 'processing_error'
      });
    }
    
    res.status(500).json({ 
      text: 'An unexpected error occurred.',
      error: 'internal_error'
    });
  }
});

// Test endpoint for development
app.post('/test', async (req, res) => {
  try {
    const { text, user = 'test-user' } = req.body;
    
    if (!text) {
      return res.status(400).json({ error: 'text_required' });
    }
    
    console.log(`🧪 Test request: "${text}"`);
    
    const copilotResponse = await axios.post(
      `${process.env.TUNNEL_URL}/process`,
      { 
        prompt: text, 
        context: { user, test: true }
      }
    );
    
    res.json({ 
      reply: copilotResponse.data.reply,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('Test endpoint error:', error.message);
    res.status(500).json({ error: 'test_failed' });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Server error:', err);
  res.status(500).json({ 
    error: 'internal_server_error',
    message: err.message 
  });
});

const port = process.env.PORT || 3000;

app.listen(port, () => {
  console.log(`🚀 Webhook multiplexer running on port ${port}`);
  console.log(`📊 Health check: http://localhost:${port}/health`);
  console.log(`🪝 Webhook endpoint: http://localhost:${port}/webhook`);
  console.log(`🧪 Test endpoint: http://localhost:${port}/test`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  process.exit(0);
});