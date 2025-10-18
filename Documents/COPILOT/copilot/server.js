// copilot/server.js
import express from 'express';
import OpenAI from 'openai';
import dotenv from 'dotenv';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import { initializeApp as initFirebase } from 'firebase/app';
import { getDatabase } from 'firebase/database';
import { Firestore } from '@google-cloud/firestore';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load environment variables
dotenv.config({ path: path.join(__dirname, '.env') });

// Configure logging
const LOG_DIR = process.env.LOG_DIR || path.join(__dirname, 'logs');
if (!fs.existsSync(LOG_DIR)) {
  fs.mkdirSync(LOG_DIR, { recursive: true });
}
function writeLog(entry) {
  const date = new Date().toISOString().slice(0, 10);
  const filePath = path.join(LOG_DIR, `${date}.log`);
  const timestamp = new Date().toISOString();
  fs.appendFileSync(filePath, `${timestamp} ${entry}\n`);
}

// Helper to read recent logs
function readRecentLogs(lines = 50) {
  const date = new Date().toISOString().slice(0,10);
  const filePath = path.join(LOG_DIR, `${date}.log`);
  if (!fs.existsSync(filePath)) return [];
  try {
    return fs.readFileSync(filePath, 'utf-8')
             .trim()
             .split('\n')
             .slice(-lines)
             .filter(line => line.trim() !== '');
  } catch (error) {
    console.warn('Failed to read recent logs:', error.message);
    return [];
  }
}

const app = express();
app.use(express.json());

// Log-check middleware - runs before /process endpoint
app.use('/process', (req, res, next) => {
  const recentLogs = readRecentLogs(20);
  req.recentLogs = recentLogs;
  
  // Extract key metrics from recent logs
  const errorCount = recentLogs.filter(line => line.includes('ERROR')).length;
  const healthChecks = recentLogs.filter(line => line.includes('HEALTH_CHECK')).length;
  const recentRequests = recentLogs.filter(line => line.includes('REQ')).length;
  
  req.logMetrics = {
    totalLines: recentLogs.length,
    errorCount,
    healthChecks,
    recentRequests,
    lastLogTime: recentLogs.length > 0 ? recentLogs[recentLogs.length - 1].substring(0, 24) : null
  };
  
  writeLog(`LOG_CHECK ${recentLogs.length} lines loaded, ${errorCount} errors, ${recentRequests} recent requests`);
  next();
});

// Initialize AI client
const openai = new OpenAI({
  apiKey: process.env.COPILOT_API_KEY || process.env.OPENAI_API_KEY
});

// Initialize Firebase and Google Cloud services
const firebaseConfig = {
  apiKey: process.env.FIREBASE_API_KEY,
  authDomain: process.env.FIREBASE_AUTH_DOMAIN,
  databaseURL: process.env.FIREBASE_DATABASE_URL,
  projectId: process.env.FIREBASE_PROJECT_ID,
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.FIREBASE_APP_ID
};

let firebaseApp, realtimeDb, firestore;

try {
  if (process.env.FIREBASE_API_KEY) {
    firebaseApp = initFirebase(firebaseConfig);
    realtimeDb = getDatabase(firebaseApp);
    console.log('✅ Firebase Realtime Database initialized');
  }
  
  if (process.env.GOOGLE_PROJECT_ID) {
    firestore = new Firestore({ projectId: process.env.GOOGLE_PROJECT_ID });
    console.log('✅ Google Firestore initialized');
  }
} catch (error) {
  console.warn('⚠️ Google Cloud/Firebase initialization failed:', error.message);
}

// Health check
app.get('/health', (req, res) => {
  writeLog('HEALTH_CHECK');
  
  // Get current log metrics for health monitoring
  const recentLogs = readRecentLogs(50);
  const logHealth = {
    totalEntries: recentLogs.length,
    recentErrors: recentLogs.filter(line => line.includes('ERROR')).length,
    recentRequests: recentLogs.filter(line => line.includes('REQ')).length,
    logFileExists: fs.existsSync(path.join(LOG_DIR, `${new Date().toISOString().slice(0,10)}.log`)),
    logDir: LOG_DIR,
    lastEntry: recentLogs.length > 0 ? recentLogs[recentLogs.length - 1].substring(0, 24) : null
  };
  
  const services = {
    openai: !!(process.env.COPILOT_API_KEY || process.env.OPENAI_API_KEY),
    firebase: !!firebaseApp,
    firestore: !!firestore
  };
  
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    port: process.env.COPILOT_PORT,
    services,
    logHealth,
    uptime: process.uptime(),
    memory: process.memoryUsage()
  });
});

// Main processing endpoint
app.post('/process', async (req, res) => {
  const logContext = `Recent: ${req.logMetrics.totalLines} logs, ${req.logMetrics.errorCount} errors, last: ${req.logMetrics.lastLogTime}`;
  writeLog(`THREAD_START ${logContext} - REQ ${JSON.stringify(req.body)}`);
  
  try {
    const { prompt, context, recentLogs: clientLogs } = req.body;
    if (!prompt) {
      writeLog('ERROR prompt_required');
      return res.status(400).json({ error: 'prompt_required' });
    }

    // Combine server logs with any client-provided logs
    const combinedContext = {
      ...context,
      serverLogMetrics: req.logMetrics,
      recentServerLogs: req.recentLogs.slice(-5), // Last 5 server logs
      clientLogs: clientLogs || []
    };

    let response;
    if (process.env.COPILOT_API_KEY || process.env.OPENAI_API_KEY) {
      // Enhanced system prompt that includes log context awareness
      const systemPrompt = `You are a helpful AI assistant integrated with Slack. You have access to recent operational logs and should consider this context when responding. 
      
Recent system status: ${req.logMetrics.errorCount} errors in last ${req.logMetrics.totalLines} log entries. 
Last activity: ${req.logMetrics.lastLogTime}. 
Recent requests: ${req.logMetrics.recentRequests}.

Provide concise, helpful responses that take into account any relevant operational context from the logs.`;

      const completion = await openai.chat.completions.create({
        model: "gpt-3.5-turbo",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: `${prompt}\n\nContext: ${JSON.stringify(combinedContext)}` }
        ],
        max_tokens: 500,
        temperature: 0.7
      });
      response = { text: completion.choices[0].message.content };
    } else {
      response = {
        text: `Context-aware echo: ${prompt} (${logContext} - processed at ${new Date().toISOString()})`
      };
    }

    writeLog(`RES ${JSON.stringify(response.text)} - Context: ${JSON.stringify(req.logMetrics)}`);
    res.json({ 
      reply: response.text, 
      timestamp: new Date().toISOString(),
      logMetrics: req.logMetrics,
      contextUsed: !!combinedContext
    });
  } catch (err) {
    writeLog(`ERROR ${err.message} - Context: ${JSON.stringify(req.logMetrics)}`);
    console.error('AI processing error:', err);
    res.status(500).json({
      error: 'processing_failed',
      message: err.message,
      timestamp: new Date().toISOString(),
      logMetrics: req.logMetrics
    });
  }
});

// Error middleware
app.use((err, req, res, next) => {
  writeLog(`MIDDLEWARE_ERROR ${err.message}`);
  console.error('Server error:', err);
  res.status(500).json({ error: 'internal_server_error', message: err.message });
});

const port = process.env.COPILOT_PORT || 4000;
app.listen(port, () => {
  writeLog(`SERVER_START port=${port} log_dir=${LOG_DIR}`);
  console.log(`🤖 Copilot agent server running on port ${port}`);
  console.log(`📊 Health check: http://localhost:${port}/health`);
  console.log(`🔄 Processing endpoint: http://localhost:${port}/process`);
  console.log(`📁 Logs directory: ${LOG_DIR}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  writeLog('SERVER_SHUTDOWN SIGTERM');
  console.log('SIGTERM received, shutting down gracefully');
  process.exit(0);
});
process.on('SIGINT', () => {
  writeLog('SERVER_SHUTDOWN SIGINT');
  console.log('SIGINT received, shutting down gracefully');
  process.exit(0);
});